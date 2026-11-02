//  WHAT: One service in the granite skill's shape: the struct with its tickets, lane and main-hopping helpers and a
//        ticketed entry per unit of work; its center (the state and one event per reducer); its one writer `Set`
//        (a case per field, the work's start, failure and reset, applied by a pure `Ops.apply`); a work reducer per
//        event (`reduce` marks the start, `effect` runs the work and writes through `set`); and the Ops' tests.
//  PIN:  ONE WRITER. Only `Set` changes the state beyond marking a start; work runs in `effect -> .run`, captures
//        the payload and its relays into lets first, and reaches its own service with `Live.service`, never a stored
//        relay (skill rules 1, 2, 5, 11).
//  PIN:  `<Service>.tickets`, NEVER `Self.tickets`, INSIDE A REDUCER. Nested in `extension FeedService`, `Self` is the
//        reducer; the service's statics are named by the service.

import Foundation

struct ServiceEmitter {
    let spec: ServiceSpec

    private var open: String { spec.isPublic ? "public " : "" }
    private var type: String { spec.type }

    /// The service's files, by their path inside its folder.
    func files() -> [(path: String, text: String)] {
        [("\(type).swift", service()), ("\(type)+Center.swift", center()), ("Reducers/\(type).Set.swift", writer())]
            + spec.events.map { ("Reducers/\(type).\($0.typeName).swift", work($0)) }
            + [("Ops/\(spec.base)Ops.swift", ops())]
    }

    private func header(_ modules: [String]) -> [String] {
        var seen: Set<String> = []
        return (modules + spec.imports).filter { seen.insert($0).inserted }.map { "import \($0)" } + [""]
    }

    // MARK: - The service

    func service() -> String {
        var lines = header(["Foundation", "Granite", "GraniteAgents", "SwiftUI"])
        if let doc = spec.doc { lines.append("/// \(SwiftName.sentence(doc))") }
        lines += ["\(open)struct \(type): GraniteService {", "    @Service(.online) \(open)var center: Center", "", "    \(open)init() {}"]
        if !spec.events.isEmpty {
            lines += ["", "    /// What the service's work answers whoever asked for it.", "    \(open)enum Reply: Sendable {"]
            for reply in spec.replies {
                lines.append(reply.type.isEmpty ? "        case \(reply.name)" : "        case \(SwiftName.member(reply.name))(\(reply.type))")
            }
            lines += ["    }", "", "    static let tickets = GraniteTickets<Reply>()"]
            if spec.hasLane {
                lines += ["", "    /// The work that writes the state runs one call at a time, in the order it was asked for.", "    static let lane = GraniteLane()"]
            }
        }
        lines += ["}", "", "extension \(type): @unchecked Sendable {}", "", "extension \(type) {",
                  "    /// Changes the state through its one writer, on main.",
                  "    \(open)func set(_ kind: Set.Meta.Kind) {",
                  "        let service = self",
                  "        onMain { service.center.set.send(Set.Meta(kind: kind)) }",
                  "    }",
                  "",
                  "    /// A binding to a field of the state, written through `set`: `\(SwiftName.relayName(type)).binding(\\.\(spec.fields.first?.name ?? "loading")) { .\(spec.fields.first?.name ?? "loading")($0) }`.",
                  "    \(open)func binding<Value>(_ keyPath: KeyPath<Center.State, Value>, _ kind: @escaping (Value) -> Set.Meta.Kind) -> Binding<Value> {",
                  "        Binding(get: { self.state[keyPath: keyPath] }, set: { self.set(kind($0)) })",
                  "    }"]
        for event in spec.events { lines += [""] + entry(event) }
        lines += ["}", ""]
        return lines.joined(separator: "\n")
    }

    private func entry(_ event: Event) -> [String] {
        var lines: [String] = []
        if let doc = event.doc { lines.append("    /// \(SwiftName.sentence(doc))") }
        let parameters = event.params.map { param -> String in
            var text = "\(SwiftName.member(param.name)): \(param.type)"
            if let value = param.defaultValue { text += " = \(value)" } else if param.type.isOptional { text += " = nil" }
            return text
        }.joined(separator: ", ")
        let arguments = (["ticket: ticket.id"] + event.params.map { "\(SwiftName.member($0.name)): \(SwiftName.member($0.name))" }).joined(separator: ", ")
        if let result = spec.resultType(event), let reply = spec.replyCase(event) {
            lines += ["    @discardableResult",
                      "    \(open)func \(event.verb)(\(parameters)) async throws -> \(result) {",
                      "        let ticket = await \(type).tickets.open()",
                      "        let service = self",
                      "        onMain { service.center.\(event.verb).send(\(event.typeName).Meta(\(arguments))) }",
                      "        guard case .\(SwiftName.member(reply))(let value) = try await \(type).tickets.wait(ticket.id) else {",
                      "            throw TicketError.refused(\"\(event.verb) answered with something else\")",
                      "        }",
                      "        return value",
                      "    }"]
        } else {
            lines += ["    \(open)func \(event.verb)(\(parameters)) async throws {",
                      "        let ticket = await \(type).tickets.open()",
                      "        let service = self",
                      "        onMain { service.center.\(event.verb).send(\(event.typeName).Meta(\(arguments))) }",
                      "        _ = try await \(type).tickets.wait(ticket.id)",
                      "    }"]
        }
        return lines
    }

    // MARK: - The center

    func center() -> String {
        var lines = header(["Foundation", "Granite", "GraniteAgents"])
        let persisted = spec.persistKey != nil
        lines += ["extension \(type) {", "    \(open)struct Center: GraniteCenter {",
                  "        \(open)struct State: \(persisted ? "GraniteState" : "TransientState") {"]
        for field in spec.fields {
            if let doc = field.doc { lines.append("            /// \(SwiftName.sentence(doc))") }
            lines.append("            \(open)var \(SwiftName.member(field.name)): \(field.type)\(Self.initial(field).map { " = \($0)" } ?? "")")
        }
        lines += ["            /// What is in flight, by the name of the work; nil when nothing is.",
                  "            \(open)var loading: String?",
                  "            /// Why the last work failed; nil once work starts again.",
                  "            \(open)var lastError: String?",
                  "",
                  "            \(open)init() {}"]
        if persisted {
            lines += ["", "            enum CodingKeys: String, CodingKey {"]
            lines += spec.fields.map { "                case \(SwiftName.member($0.name))" }
            lines += ["            }", "",
                      "            /// A field missing from the stored file, or stored as another type, reads as its default, so the",
                      "            /// state keeps reading after a field is added; what is in flight is never stored.",
                      "            \(open)init(from decoder: Decoder) throws {",
                      "                let container = try decoder.container(keyedBy: CodingKeys.self)"]
            for field in spec.fields {
                let name = SwiftName.member(field.name)
                if field.type.isOptional {
                    let fallback = field.defaultValue.map { " ?? \($0)" } ?? ""
                    lines.append(fallback.isEmpty
                                 ? "                \(name) = try? container.decodeIfPresent(\(field.type.unwrapped).self, forKey: .\(name))"
                                 : "                \(name) = (try? container.decodeIfPresent(\(field.type.unwrapped).self, forKey: .\(name)))\(fallback)")

                } else {
                    lines.append("                \(name) = (try? container.decodeIfPresent(\(field.type).self, forKey: .\(name))) ?? \(Self.initial(field) ?? "nil")")
                }
            }
            lines.append("            }")
        }
        lines += ["        }", "", "        @Event \(open)var set: Set.Reducer"]
        lines += spec.events.map { "        @Event \(open)var \($0.verb): \($0.typeName).Reducer" }
        lines.append("")
        if let key = spec.persistKey {
            lines.append("        @Store(persist: \"\(key)\", autoSave: true, preload: true) \(open)var state: State")
        } else {
            lines.append("        @Store \(open)var state: State")
        }
        lines += ["", "        \(open)init() {}", "    }", "}", ""]
        return lines.joined(separator: "\n")
    }

    /// The value a field starts at: the line's default, or an empty value of Swift's own types; nil for an optional.
    static func initial(_ field: Field) -> String? {
        if let value = field.defaultValue { return value }
        return Samples.zero(field.type)
    }

    // MARK: - The writer

    func writer() -> String {
        var lines = header(["Foundation", "Granite"])
        lines += ["extension \(type) {",
                  "    /// The state's one writer: every change is a kind, applied on main by `\(spec.base)Ops.apply`.",
                  "    \(open)struct Set: GraniteReducer {",
                  "        \(open)typealias Center = \(type).Center",
                  "        \(open)init() {}",
                  "",
                  "        \(open)struct Meta: GranitePayload {",
                  "            \(open)enum Kind: Sendable {"]
        for field in spec.fields { lines.append("                case \(SwiftName.member(field.name))(\(field.type))") }
        for field in appended { lines.append("                case \(Self.appendCase(field.name))(\(field.type.element.map { "[\($0)]" } ?? "\(field.type)"))") }
        lines += ["                case loading(String?)", "                case failed(String)", "                case clear",
                  "            }", "", "            \(open)var kind: Kind", "",
                  "            \(open)init(kind: Kind) { self.kind = kind }", "        }", "",
                  "        @Payload \(open)var meta: Meta?", "",
                  "        \(open)func reduce(state: inout Center.State) {",
                  "            guard let meta else { return }",
                  "            \(spec.base)Ops.apply(meta.kind, to: &state)",
                  "        }", "",
                  "        \(open)var thread: DispatchQueue? { \(spec.setThread) }",
                  "    }", "}", ""]
        return lines.joined(separator: "\n")
    }

    /// The fields some work appends to.
    private var appended: [Field] {
        var seen: Set<String> = []
        return spec.events.compactMap { event -> Field? in
            guard case .append(let name) = event.write, seen.insert(name).inserted else { return nil }
            return spec.field(name)
        }
    }

    static func appendCase(_ field: String) -> String { "append" + SwiftName.upperFirst(field) }

    /// Whether an expression is a literal (`[]`, `nil`, `0`, `"x"`): it needs no `try await`, which would only warn.
    static func isLiteral(_ expression: String) -> Bool {
        expression.range(of: #"^(\[\]|\[:\]|nil|true|false|-?\d+(\.\d+)?|"[^"\\]*")$"#, options: .regularExpression) != nil
    }


    // MARK: - A unit of work

    func work(_ event: Event) -> String {
        var lines = header(["Foundation", "Granite", "GraniteAgents"])
        let relays = spec.relays(of: event)
        lines.append("extension \(type) {")
        if let doc = event.doc { lines.append("    /// \(SwiftName.sentence(doc))") }
        lines += ["    \(open)struct \(event.typeName): GraniteReducer {",
                  "        \(open)typealias Center = \(type).Center",
                  "        \(open)init() {}",
                  "",
                  "        \(open)struct Meta: GranitePayload {",
                  "            \(open)let ticket: UUID"]
        lines += event.params.map { "            \(open)let \(SwiftName.member($0.name)): \($0.type)" }
        lines += ["        }", "", "        @Payload \(open)var meta: Meta?"]
        if !relays.isEmpty {
            lines.append("")
            lines += relays.map { "        @Relay var \(SwiftName.member($0.name)): \($0.type)" }
        }
        lines += ["",
                  "        /// Marks the work's start; the state changes through `set` when it ends.",
                  "        \(open)func reduce(state: inout Center.State) {",
                  "            guard meta != nil else { return }",
                  "            state.loading = \"\(event.verb)\"",
                  "            state.lastError = nil",
                  "        }",
                  "",
                  "        \(open)func effect(state: Center.State) -> GraniteEffect {",
                  "            guard let meta else { return .none }",
                  "            let service = Live.service(\(type).self)",
                  "            let ticket = meta.ticket"]
        lines += event.params.map { "            let \(SwiftName.member($0.name)) = meta.\(SwiftName.member($0.name))" }
        lines += relays.map { "            let \(SwiftName.member($0.name)) = self.\(SwiftName.member($0.name))" }
        lines += ["            return .run {", "                do {"]
        let call: String
        if let expression = event.expression {
            call = expression
        } else {
            let arguments = event.params.map { "\(SwiftName.member($0.name)): \(SwiftName.member($0.name))" }
                + relays.map { "\(SwiftName.member($0.name)): \(SwiftName.member($0.name))" }
            call = "\(event.typeName).work(\(arguments.joined(separator: ", ")))"
        }
        switch event.write {
        case .none:
            if let expression = event.expression, Self.isLiteral(expression) {
                lines.append("                    _ = \(call)")
            } else {
                lines.append(event.expression == nil ? "                    try await \(call)" : "                    _ = try await \(call)")
            }

            lines += ["                    service.set(.loading(nil))", "                    await \(type).tickets.resolve(ticket, with: .done)"]
        case .replace(let field), .append(let field):
            let result = spec.resultType(event) ?? "Void"
            var marked = event.expression.map(Self.isLiteral) == true ? call : "try await \(call)"
            // An optional field filled by a call that answers the value itself: a generic closure does not promote it
            // (`cannot convert value of type 'User' to closure result type 'User?'`, Margin 2026-11-01).
            // A closure whose result is spelled out takes either the value or an optional of it.
            if result.hasSuffix("?"), marked.hasPrefix("try await ") { marked = "() async throws -> \(result) in \(marked)" }
            lines.append("                    let value: \(result) = try await \(type).lane.run { \(marked) }")


            if case .append = event.write {
                lines.append("                    service.set(.\(Self.appendCase(field))(value))")
            } else {
                lines.append("                    service.set(.\(SwiftName.member(field))(value))")
            }
            lines += ["                    service.set(.loading(nil))",
                      "                    await \(type).tickets.resolve(ticket, with: .\(SwiftName.member(spec.replyCase(event) ?? field))(value))"]
        }
        lines += ["                } catch {",
                  "                    service.set(.failed(error.localizedDescription))",
                  "                    await \(type).tickets.fail(ticket, error)",
                  "                }", "            }", "        }", "",
                  "        \(open)var thread: DispatchQueue? { .main }"]
        if event.expression == nil, let body = spec.bodies[event.verb] {
            let parameters = event.params.map { "\(SwiftName.member($0.name)): \($0.type)" } + relays.map { "\(SwiftName.member($0.name)): \($0.type)" }
            lines += [""]
            lines.append("        static func work(\(parameters.joined(separator: ", "))) async throws\(spec.resultType(event).map { " -> \($0)" } ?? "") {")
            lines.append(BodyAsk.indented(body, by: 12))
            lines.append("        }")
        }
        lines += ["    }", "}", ""]
        return lines.joined(separator: "\n")
    }

    /// The work function the model's body goes in, alone in a file: what `BodyAsk` parses.
    func workFile(_ event: Event, body: String) -> String {
        let relays = spec.relays.filter { body.range(of: #"\b\#($0.name)\b"#, options: .regularExpression) != nil }
        let parameters = event.params.map { "\(SwiftName.member($0.name)): \($0.type)" } + relays.map { "\(SwiftName.member($0.name)): \($0.type)" }
        return "func work(\(parameters.joined(separator: ", "))) async throws\(spec.resultType(event).map { " -> \($0)" } ?? "") {\n\(BodyAsk.indented(body, by: 4))\n}\n"
    }

    // MARK: - Ops

    func ops() -> String {
        var lines = header(["Foundation"])
        lines += ["/// Every change to \(type)'s state, as one function a test can run without a relay.",
                  "\(open)enum \(spec.base)Ops {",
                  "    \(open)static func apply(_ kind: \(type).Set.Meta.Kind, to state: inout \(type).Center.State) {",
                  "        switch kind {"]
        for field in spec.fields {
            let name = SwiftName.member(field.name)
            lines += ["        case .\(name)(let value):", "            state.\(name) = value"]
        }
        for field in appended {
            let name = SwiftName.member(field.name)
            lines.append("        case .\(Self.appendCase(field.name))(let value):")
            lines.append(field.type.isOptional ? "            state.\(name) = (state.\(name) ?? []) + value" : "            state.\(name).append(contentsOf: value)")
        }
        lines += ["        case .loading(let key):", "            state.loading = key", "            if key != nil { state.lastError = nil }",
                  "        case .failed(let message):", "            state.lastError = message", "            state.loading = nil",
                  "        case .clear:", "            state = .init()",
                  "        }", "    }", "}", ""]
        return lines.joined(separator: "\n")
    }

    // MARK: - Tests

    /// The Ops' tests: one a kind, run without a relay. `module` is what they `@testable import`.
    func tests(module: String, previews: Set<String>, enums: [String: [String]]) -> String {
        let state = "\(type).Center.State"
        var lines = ["import Foundation", "import Testing", "@testable import \(module)", "",
                     "/// \(type)'s state changes, one a kind: what its writer does, run without a relay.",
                     "struct \(spec.base)OpsTests {"]
        for field in spec.fields {
            let name = SwiftName.member(field.name)
            guard let value = Samples.value(field.type, previews: previews, enums: enums) ?? field.defaultValue else { continue }
            lines += ["    @Test func writes\(SwiftName.upperFirst(field.name))() {",
                      "        var state = \(state)()",
                      "        let value: \(field.type) = \(value)",
                      "        \(spec.base)Ops.apply(.\(name)(value), to: &state)",
                      "        #expect(state.\(name) == value)",
                      "    }", ""]
        }
        for field in appended {
            guard let element = field.type.element, let value = Samples.value(element, previews: previews, enums: enums) else { continue }
            let name = SwiftName.member(field.name)
            lines += ["    @Test func appendsTo\(SwiftName.upperFirst(field.name))() {",
                      "        var state = \(state)()",
                      "        let page: [\(element)] = [\(value)]",
                      "        \(spec.base)Ops.apply(.\(Self.appendCase(field.name))(page), to: &state)",
                      "        \(spec.base)Ops.apply(.\(Self.appendCase(field.name))(page), to: &state)",
                      "        #expect(state.\(name) == page + page)",
                      "    }", ""]
        }
        lines += ["    @Test func workInFlightIsMarked() {",
                  "        var state = \(state)()",
                  "        \(spec.base)Ops.apply(.failed(\"offline\"), to: &state)",
                  "        \(spec.base)Ops.apply(.loading(\"\(spec.events.first?.verb ?? "work")\"), to: &state)",
                  "        #expect(state.loading == \"\(spec.events.first?.verb ?? "work")\")",
                  "        #expect(state.lastError == nil)",
                  "    }", "",
                  "    @Test func aFailureSaysWhyAndEndsTheWork() {",
                  "        var state = \(state)()",
                  "        \(spec.base)Ops.apply(.loading(\"\(spec.events.first?.verb ?? "work")\"), to: &state)",
                  "        \(spec.base)Ops.apply(.failed(\"offline\"), to: &state)",
                  "        #expect(state.lastError == \"offline\")",
                  "        #expect(state.loading == nil)",
                  "    }", "",
                  "    @Test func clearStartsOver() {",
                  "        var state = \(state)()",
                  "        \(spec.base)Ops.apply(.loading(\"\(spec.events.first?.verb ?? "work")\"), to: &state)",
                  "        \(spec.base)Ops.apply(.clear, to: &state)",
                  "        #expect(state == \(state)())",
                  "    }", "}", ""]
        return lines.joined(separator: "\n")
    }
}
