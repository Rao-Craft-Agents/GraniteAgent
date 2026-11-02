//  WHAT: `make: service`: one service in the skill's single-writer shape, into the app's Services folder or a kit's
//        (then public), its work's bodies from the call's expressions or the host's model, a relay to it in the root
//        that holds them, and its Ops tests in the app's or the kit's test target.
//  PIN:  RELAYS POINT DOWN. A relay to the service itself, or to a service whose reducers reach back to it, recurses
//        at construction (skill rule 11): the call is refused, never written.
//  PIN:  EVERYTHING WRONG AT ONCE. Every line is read and every rule checked before the model is asked or anything
//        is written, so one answer fixes the call.

import Foundation
import GraniteAgents

struct ServiceMake {
    let input: GraniteAppAgent.Input
    let workspace: Workspace
    let model: (any AgentHostModel)?
    let note: @Sendable (String) -> Void
    let yield: (GraniteFrame) -> Void

    static let reservedFields: Set<String> = ["loading", "lastError", "failed", "clear", "set", "center", "state"]

    func plan() async throws -> Plan {
        var problems: [String] = []
        guard let typeText = input.type?.trimmingCharacters(in: .whitespaces), !typeText.isEmpty else {
            throw GraniteError.refused(["name the service with `type`, like `Feed` (it becomes FeedService)"])
        }
        let (type, base) = SwiftName.service(typeText)
        guard SwiftName.isTypeName(base) else { throw GraniteError.refused(["`\(typeText)` is not a type name in UpperCamelCase"]) }
        let index = ProjectIndex(root: workspace.root)

        var fields: [Field] = []
        for line in input.state ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let field = try FieldLine.parseField(line, in: line)
                if field.name == "loading" || field.name == "lastError" { continue }
                if Self.reservedFields.contains(field.name) { problems.append("`\(field.name)` is the service's own; name the field something else"); continue }
                if fields.contains(where: { $0.name == field.name }) { problems.append("the field `\(field.name)` is named twice"); continue }
                if ServiceEmitter.initial(field) == nil, !field.type.isOptional {
                    problems.append("`\(line)` needs a default (`= …`) or `?`: a service's state starts before any work has run")
                }
                fields.append(field)
            } catch { problems.append("\(error)") }
        }
        var events: [Event] = []
        for line in input.events ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let event = try EventLine.parse(line)
                if events.contains(where: { $0.verb == event.verb }) { problems.append("the work `\(event.verb)` is named twice"); continue }
                if SwiftName.keywords.contains(event.verb) { problems.append("`\(event.verb)` is a Swift keyword; name the work something else"); continue }
                if let name = event.write.field {
                    if let field = fields.first(where: { $0.name == name }) {
                        if case .append = event.write, field.type.element == nil {
                            problems.append("`\(event.verb)` appends to `\(name)`, which is not a list (`+>` adds a page to a list; `->` replaces)")
                        }
                    } else {
                        problems.append("`\(event.verb)` writes `\(name)`, and the state has no `\(name)`: add it to `state`")
                    }
                }
                events.append(event)
            } catch { problems.append("\(error)") }
        }
        // A call that answers an envelope (a page with its list and a total) is read for the member the field holds.
        var unwrapped: [String] = []
        for position in events.indices {
            guard let name = events[position].write.field, let field = fields.first(where: { $0.name == name }),
                  let expression = events[position].expression,
                  let read = Self.unwrap(expression, into: "\(field.type)", index: index) else { continue }
            events[position].expression = expression.trimmingCharacters(in: .whitespaces) + "." + read.member
            unwrapped.append("`\(events[position].verb)` reads `.\(read.member)` of the \(read.answer) that `\(read.method)(…)` answers")
        }
        // A call whose answer the index knows, and which cannot fill the field, is refused with the calls that can.
        for event in events {
            guard let name = event.write.field, let field = fields.first(where: { $0.name == name }),
                  let expression = event.expression, let problem = Self.misfit(expression, field: field, index: index) else { continue }
            problems.append("`\(event.verb)`: " + problem)
        }
        var relays: [Relay] = []
        for line in input.relays ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let relay = try RelayLine.parse(line)
                if relay.type == type {
                    problems.append("\(type) cannot hold a relay to itself: its reducers reach it with `Live.service` (a stored relay to itself recurses at construction)")
                } else if index.services[relay.type] == nil {
                    problems.append(RelayLine.missing(line, relay: relay, declared: index.declared))
                } else if index.reaches(relay.type, type) {
                    problems.append("\(relay.type)'s reducers already reach \(type): a relay back would close a loop that recurses at construction; let one of them call the other through the root")
                } else if EventLine.reservedParameters.contains(relay.name) || events.contains(where: { $0.params.contains { $0.name == relay.name } }) {
                    problems.append("the relay `\(relay.name)` shares a name with a parameter or the reducer's own; name it something else (`name: \(relay.type)`)")
                } else {
                    relays.append(relay)
                }
            } catch { problems.append("\(error)") }
        }
        // A call sees the event's parameters, its relays and the state; a name it cannot see does not build.
        for event in events {
            guard let expression = event.expression else { continue }
            let seen = Set(event.params.map(\.name) + relays.map(\.name) + ["state"])
            let unseen = Self.roots(of: expression).filter { !seen.contains($0) }
            guard !unseen.isEmpty else { continue }
            var ways = ["its parameters (" + (event.params.isEmpty ? "none" : event.params.map { "`\($0.name)`" }.joined(separator: ", ")) + ")"]
            if !relays.isEmpty { ways.append("its relays (" + relays.map { "`\($0.name)`" }.joined(separator: ", ") + ")") }
            let stateNames = unseen.filter { name in fields.contains { $0.name == name } }
            ways.append(stateNames.isEmpty ? "the state as `state.<field>`" : "the state as " + stateNames.map { "`state.\($0)`" }.joined(separator: ", "))
            let clients = index.declared.filter { $0.hasSuffix("Client") }.sorted()
            let reach = clients.isEmpty ? "" : "; a client is reached by its type (`\(clients[0])…`)"
            problems.append("`\(event.verb)` uses " + unseen.map { "`\($0)`" }.joined(separator: ", ")
                            + ", which its work cannot see: it sees " + ways.joined(separator: ", ") + reach)
        }
        // A client no package declares (`SocialAPI.loadFeed(…)`, Margin 2026-11-01) cannot build. When the app has a client,
        // the refusal names it: told to "make the client first" while `MarginClient` existed, the model gave up on the agent
        // (Margin c4, 2026-11-01). Only names that read as a client are held to this; a framework's types are not known here.
        let clientSuffixes = ["API", "Client", "Kit", "Store", "Repository", "Backend", "Server"]
        // A client first by its name (`…Client`, `…API`); a store or a kit only when the app has nothing named so. Margin
        // c8, 2026-11-02: `KeychainTokenStore` and `MemoryTokenStore` were offered beside `MarginClient` as the app's client.
        let named = { (suffixes: [String]) in index.declared.filter { name in name.first?.isUppercase == true && suffixes.contains { name.hasSuffix($0) } }.sorted() }
        let appClients = named(["Client", "API"]).isEmpty ? named(clientSuffixes) : named(["Client", "API"])
        for event in events {
            guard let expression = event.expression?.trimmingCharacters(in: .whitespaces),
                  let root = expression.split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "_") }).first.map(String.init),
                  root.first?.isUppercase == true, !index.declared.contains(root),
                  clientSuffixes.contains(where: { root.hasSuffix($0) }) else { continue }
            if appClients.isEmpty {
                problems.append("`\(event.verb)` calls `\(root)`, which the project does not declare: make the app's API client first "
                                + "(`$network`, with `$models` for its types and `$mocks` for data before a server exists), then call it by its type")
            } else {
                problems.append("`\(event.verb)` calls `\(root)`, which the project does not declare; the app's client is "
                                + appClients.prefix(3).map { "`\($0)`" }.joined(separator: " or ") + ": call it by that type")
            }
        }
        // `MarginClient.posts(…)` on the type, when `posts` is only ever an instance's (Margin, 2026-11-01).
        for event in events {
            guard let expression = event.expression?.trimmingCharacters(in: .whitespaces),
                  let match = expression.range(of: #"^([A-Z]\w*)\.([a-z]\w*)\("#, options: .regularExpression) else { continue }
            let head = expression[match].dropLast()
            let parts = head.split(separator: ".").map(String.init)
            guard parts.count == 2, index.declared.contains(parts[0]), index.instances.contains(parts[1]), !index.statics.contains(parts[1]) else { continue }
            let shared = index.shared.contains(parts[0])
            problems.append("`\(event.verb)` calls `\(parts[0]).\(parts[1])(…)` on the type, and `\(parts[1])` is an instance's: "
                            + (shared ? "call it on the shared one (`\(parts[0]).current.\(parts[1])(…)`)" : "call it on an instance (`\(parts[0])().\(parts[1])(…)`, or the one the app keeps)"))
        }
        // A call on a type the project declares must name a function it has, with labels one of its declarations takes
        // (Margin, 2026-11-01: `posts(page:per_page:)` for `posts(page:perPage:)`, and a `users(…)` no one declared).
        for event in events {
            guard let expression = event.expression?.trimmingCharacters(in: .whitespaces), let problem = Self.mislabelled(expression, index: index) else { continue }
            problems.append("`\(event.verb)`: " + problem)
        }
        let needsBodies = events.filter { $0.expression == nil }
        if !needsBodies.isEmpty, model == nil {
            problems.append("\(needsBodies.map(\.verb).joined(separator: ", ")) \(needsBodies.count == 1 ? "has" : "have") no `= expression`, and this host has no model to write the work: give the call that does it")
        }
        let placement = Placement.resolve(into: input.into, type: type, kind: "Services", workspace: workspace)
        // Made again with less work: a reducer left behind would name what the service no longer has.
        let reducers = placement.folder.appendingPathComponent("Reducers")
        let kept = Set(events.map { "\(type).\($0.typeName).swift" } + ["\(type).Set.swift"])
        for name in ((try? FileManager.default.contentsOfDirectory(atPath: reducers.path)) ?? []).sorted()
        where name.hasPrefix(type + ".") && name.hasSuffix(".swift") && !kept.contains(name) {
            let verb = SwiftName.lowerFirst(String(name.dropFirst(type.count + 1).dropLast(6)))
            problems.append("\(type) already does `\(verb)` (\(workspace.files.relative(reducers.appendingPathComponent(name)))): keep its line in `events`, or delete that file first")
        }
        guard problems.isEmpty else { throw GraniteError.refused(problems) }

        yield(.read(make: .service, lines: fields.count + events.count + relays.count))

        var spec = ServiceSpec(type: type, base: base, fields: fields, events: events, relays: relays, persistKey: nil,
                               isPublic: placement.package != nil, imports: input.imports ?? [], doc: input.notes.map(Self.firstSentence))
        if input.persist == true {
            let owner = placement.package?.name ?? workspace.appName ?? "app"
            spec.persistKey = Self.persistKey(owner: owner, base: base, fields: fields, existing: placement.folder.appendingPathComponent("\(type)+Center.swift"))
        }
        spec.imports += ModuleImports.modules(for: [fields.map(\.type.description).joined(separator: " "),
                                                    events.compactMap(\.expression).joined(separator: " "),
                                                    events.flatMap(\.params).map(\.type.description).joined(separator: " ")],
                                              index: index, besides: placement.package?.target)

        // The work no line says how to do, written by the host's model.
        if let model, !needsBodies.isEmpty {
            let asker = BodyAsk(model: model, rounds: min(max(input.rounds ?? 3, 1), 5), note: note)
            for event in needsBodies {
                note("asking for \(type).\(event.verb)'s work")
                let emitter = ServiceEmitter(spec: spec)
                let (body, rounds) = try await asker.ask(
                    "\(type).\(event.verb)", system: BodyPrompts.work, user: Self.workPrompt(event, spec: spec, index: index, notes: input.notes),
                    file: { emitter.workFile(event, body: $0) },
                    check: { body in spec.resultType(event) != nil && !body.contains("return") ? ["it never returns: end with `return` and a value of \(spec.resultType(event)!)"] : [] })
                spec.bodies[event.verb] = body
                yield(.asked(type: "\(type).\(event.verb)", rounds: rounds))
            }
        }

        var plan = Plan()
        let emitter = ServiceEmitter(spec: spec)
        for (path, text) in emitter.files() { plan.write(placement.folder.appendingPathComponent(path), text, role: placement.package == nil ? .app : .other) }
        plan.types = [type] + events.map { "\(type).\($0.typeName)" }

        // The tests: the kit's test target, or the app's.
        let enums = index.types.filter { $0.value.kind == "enum" }.mapValues(\.cases)
        if let package = placement.package {
            if let tests = package.tests {
                plan.write(tests.appendingPathComponent("\(base)OpsTests.swift"), emitter.tests(module: package.target, previews: index.previews, enums: enums), role: .other)
            } else {
                plan.notes.append("\(package.name) has no test target, so \(base)Ops has no tests")
            }
        } else if let (folder, module) = try workspace.unitTests() {

            plan.write(folder.appendingPathComponent("\(base)OpsTests.swift"), emitter.tests(module: module, previews: index.previews, enums: enums), role: .tests)
        } else {
            plan.notes.append("the project has no unit-test target, so \(base)Ops has no tests")
        }

        // The root that holds every service's relay.
        let rootFile = placement.package.flatMap { package in index.kitRoots.values.first { $0.path.hasPrefix(package.root.path + "/") } } ?? (placement.package == nil ? index.appRoot : nil)
        if let rootFile, let text = plan.text(at: rootFile) ?? (try? String(contentsOf: rootFile, encoding: .utf8)) {
            if let edited = RootEditor.adding(type, as: SwiftName.relayName(type), isPublic: placement.package != nil, to: text) {
                plan.write(rootFile, edited, role: placement.package == nil ? .app : .other)
                plan.notes.append("\(rootFile.deletingPathExtension().lastPathComponent) holds a relay to \(type), so it is hosted for the life of the app")
            }
        } else {
            plan.notes.append("no root holds the relays, so \(type) is hosted by the first page that reads it")
        }
        plan.notes += unwrapped
        if spec.hasLane { plan.notes.append("\(type)'s work that writes the state runs one call at a time, in order, through its lane") }
        if let key = spec.persistKey { plan.notes.append("\(type)'s state persists under \(key); a page reads it once `\(SwiftName.relayName(type)).isLoaded`") }
        return plan
    }

    /// The store's key: the one the service already persists under, bumped when a field it keeps changed type.
    static func persistKey(owner: String, base: String, fields: [Field], existing: URL) -> String {
        let fresh = "persistence.\(owner).\(base.lowercased()).0001"
        guard let text = try? String(contentsOf: existing, encoding: .utf8),
              let key = text.matches(#"persist:\s*"([^"]+)""#).first else { return fresh }
        let kept = ProjectIndex.members(of: text.components(separatedBy: "\n"),
                                        from: text.components(separatedBy: "\n").firstIndex { $0.contains("struct State") } ?? 0,
                                        indent: (text.components(separatedBy: "\n").first { $0.contains("struct State") }?.prefix { $0 == " " }.count) ?? 8).0
        let changed = fields.contains { field in kept.contains { $0.name == field.name && $0.type != field.type.description } }
        guard changed, let dot = key.lastIndex(of: "."), let number = Int(key[key.index(after: dot)...]) else { return key }
        return key[..<dot] + "." + String(format: "%04d", number + 1)
    }

    static func firstSentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let end = trimmed.firstIndex(where: { ".!?".contains($0) }) { return String(trimmed[...end]) }
        return trimmed
    }

    /// What the model is told about one unit of work: the function, the state it serves, the services and types it
    /// may use.
    /// The member of what `expression` answers that the field holds, when the answer is not the field's type: a page
    /// envelope (`PostPage`) read for its list (`.posts`). Nil when the call answers the field's type, when its answer
    /// is not known (or two functions of its name answer differently), or when no single member fits.
    static func unwrap(_ expression: String, into fieldType: String, index: ProjectIndex) -> (member: String, answer: String, method: String)? {
        let call = expression.trimmingCharacters(in: .whitespaces)
        guard call.hasSuffix(")"), let method = Self.method(of: call), let answers = index.returns[method], answers.count == 1,
              let answer = answers.first.map(Self.plain) else { return nil }
        let wanted = Self.plain(fieldType)
        guard answer != wanted, let info = index.types[answer] else { return nil }
        let fitting = info.fields.filter { Self.plain($0.type) == wanted }
        guard fitting.count == 1 else { return nil }
        return (fitting[0].name, answer, method)
    }

    /// Why `expression` cannot fill `field`, when the index knows what its function answers and the answer is neither
    /// the field's type nor an envelope of it; with the functions whose answer can (Hearth, 2026-11-01: a `Pages<Post>`
    /// sequence and a `Session` written into `[Post]` and `User?` fields did not build).
    static func misfit(_ expression: String, field: Field, index: ProjectIndex) -> String? {
        let call = expression.trimmingCharacters(in: .whitespaces)
        guard call.hasSuffix(")"), let method = Self.method(of: call), let answers = index.returns[method], answers.count == 1,
              let answer = answers.first else { return nil }
        let wanted = "\(field.type)"
        guard Self.plain(answer) != Self.plain(wanted), Self.unwrap(call, into: wanted, index: index) == nil else { return nil }
        var fitting: [String] = []
        for (other, types) in index.returns.sorted(by: { $0.key < $1.key }) where types.count == 1 && other != method {
            let type = types.first!
            if Self.plain(type) == Self.plain(wanted) {
                fitting.append("`\(other)(…)` answers `\(type)`")
            } else if Self.plain(wanted).hasPrefix("["), let info = index.types[Self.plain(type)],
                      let member = info.fields.first(where: { Self.plain($0.type) == Self.plain(wanted) }),
                      info.fields.filter({ Self.plain($0.type) == Self.plain(wanted) }).count == 1 {
                // Only a list is read out of an answer: a page's `.posts`, never a post's `.author`.
                fitting.append("`\(other)(…)` answers `\(type)`, read for its `.\(member.name)`")
            }
        }
        var offers = ["keep the call and drop the write (`verb(…) = \(method)(…)` answers when it is done), and fill `\(field.name)` in another event"]
        if !fitting.isEmpty { offers.insert("call one that does: " + fitting.prefix(3).joined(separator: "; "), at: 0) }
        return "`\(method)(…)` answers `\(answer)`, and `\(field.name)` holds `\(wanted)`: " + offers.joined(separator: "; or ")
    }

    /// The names a call starts from: its receiver (`client` in `client.load(page)`) and each argument's first name
    /// (`page` in `page + 1`), leaving out labels, members, literals, types and Swift's own words.
    static func roots(of expression: String) -> [String] {
        let keywords: Set<String> = ["try", "await", "true", "false", "nil", "self", "as", "is", "in", "let", "var", "some", "any"]
        let characters = Array(expression)
        var names: [String] = [], position = 0, inString = false
        func previous(_ index: Int) -> Character? {
            var cursor = index - 1
            while cursor >= 0, characters[cursor] == " " { cursor -= 1 }
            return cursor >= 0 ? characters[cursor] : nil
        }
        func next(_ index: Int) -> Character? {
            var cursor = index
            while cursor < characters.count, characters[cursor] == " " { cursor += 1 }
            return cursor < characters.count ? characters[cursor] : nil
        }
        while position < characters.count {
            let character = characters[position]
            if character == "\"" { inString.toggle(); position += 1; continue }
            guard !inString, character.isLetter || character == "_" else { position += 1; continue }
            var end = position
            while end < characters.count, characters[end].isLetter || characters[end].isNumber || characters[end] == "_" { end += 1 }
            let name = String(characters[position..<end])
            let before = previous(position)
            let starts = before == nil || before == "(" || before == "," || before == ":" || before == "[" || before == "!"
                || before == "+" || before == "-" || before == "*" || before == "/" || before == "=" || before == "?"
            // A word that starts a value, is not a label (`page:`), a member (`.posts`), a type or Swift's own.
            if starts, next(end) != ":", before != "$", name.first?.isLowercase == true, !keywords.contains(name), !names.contains(name) {
                if !(before == "(" && position >= 1 && characters[position - 1] == "\\") { names.append(name) }
            }
            position = end
        }
        return names
    }

    /// Why `expression`'s last call cannot be made as written, when its receiver starts from a type the project
    /// declares: a function declared nowhere, or labels none of its declarations takes.
    static func mislabelled(_ expression: String, index: ProjectIndex) -> String? {
        // A member read off the answer (`.posts`) is not part of the call.
        let call = expression.replacingOccurrences(of: #"\)\.[A-Za-z_]\w*$"#, with: ")", options: .regularExpression)
        guard let root = call.split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "_") }).first.map(String.init),
              root.first?.isUppercase == true, index.declared.contains(root),
              call.hasSuffix(")"), let method = Self.method(of: call), method != root else { return nil }
        guard let declared = index.parameters[method], !declared.isEmpty else {
            return "`\(method)(…)` is declared nowhere in the project: call a function its client has"
        }
        // The labels the call gives, in order.
        var depth = 0, open: String.Index?
        for position in call.indices.reversed() {
            if call[position] == ")" { depth += 1 } else if call[position] == "(" { depth -= 1; if depth == 0 { open = position; break } }
        }
        guard let open else { return nil }
        let inside = String(call[call.index(after: open)..<call.index(before: call.endIndex)])
        let given: [String] = ProjectIndex.topLevel(inside).compactMap { piece in
            let text = piece.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { return nil }
            if let colon = text.firstIndex(of: ":"), text[..<colon].allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) { return String(text[..<colon]) }
            return ""
        }
        func fits(_ list: [(label: String, defaulted: Bool)]) -> Bool {
            var next = 0
            for parameter in list {
                if next < given.count, given[next] == parameter.label { next += 1 } else if !parameter.defaulted { return false }
            }
            return next == given.count
        }
        guard !declared.contains(where: fits) else { return nil }
        let shown = given.map { $0.isEmpty ? "_:" : "\($0):" }.joined()
        let ways = declared.prefix(3).map { list in "`\(method)(" + list.map { ($0.label.isEmpty ? "_" : $0.label) + ":" }.joined() + ")`" }
        return "`\(method)(\(shown))` takes no labels of its declarations: it is \(ways.joined(separator: " or "))"
    }

    /// The function a call ends in: `posts` in `HearthClient.current.posts(page: page)`.
    static func method(of call: String) -> String? {
        var depth = 0
        var open: String.Index?
        for position in call.indices.reversed() {
            if call[position] == ")" { depth += 1 } else if call[position] == "(" {
                depth -= 1
                if depth == 0 { open = position; break }
            }
        }
        guard let open else { return nil }
        let name = String(call[..<open].reversed().prefix { $0.isLetter || $0.isNumber || $0 == "_" }.reversed())
        return name.isEmpty ? nil : name
    }

    /// A type as compared: no spaces, no `?` at its end.
    static func plain(_ type: String) -> String {
        var text = type.replacingOccurrences(of: " ", with: "")
        while text.hasSuffix("?") || text.hasSuffix("!") { text.removeLast() }
        if text.hasPrefix("Optional<"), text.hasSuffix(">") { text = String(text.dropFirst(9).dropLast()) }
        if text.hasPrefix("Array<"), text.hasSuffix(">") { text = "[" + text.dropFirst(6).dropLast() + "]" }
        return text
    }

    static func workPrompt(_ event: Event, spec: ServiceSpec, index: ProjectIndex, notes: String?) -> String {
        let parameters = event.params.map { "\($0.name): \($0.type)" } + spec.relays.map { "\($0.name): \($0.type)" }
        var lines = ["Function: static func work(\(parameters.joined(separator: ", "))) async throws\(spec.resultType(event).map { " -> \($0)" } ?? "")"]
        lines.append("What it does: \(event.doc ?? SwiftName.words(event.verb))")
        if let field = event.write.field {
            lines.append("Its result \(event.write == .append(field) ? "is appended to" : "replaces") \(spec.type)'s `\(field)`.")
        }
        lines.append("\(spec.type)'s state: " + spec.fields.map { "\($0.name) \($0.type)" }.joined(separator: ", "))
        for relay in spec.relays {
            if let service = index.services[relay.type] {
                let entries = service.signatures.filter { !$0.contains("func set(") && !$0.contains("func binding") }
                lines.append("\(relay.name) (\(relay.type)): state \(service.fields.map { "\($0.name) \($0.type)" }.joined(separator: ", ")); entries: \(entries.joined(separator: "; "))")
            }
        }
        var mentioned = Set(event.params.flatMap(\.type.names) + spec.fields.flatMap(\.type.names))
        mentioned.formIntersection(index.types.keys)
        for name in mentioned.sorted() {
            if let info = index.types[name] {
                lines.append("\(name): " + (info.kind == "enum" ? info.cases.joined(separator: " | ") : info.fields.map { "\($0.name) \($0.type)" }.joined(separator: ", ")))
            }
        }
        if let notes, !notes.isEmpty { lines.append("About the app: \(notes)") }
        lines.append("Write the body of work, for this app, in its own names.")
        return lines.joined(separator: "\n")
    }
}
