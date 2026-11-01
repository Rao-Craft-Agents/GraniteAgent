//  WHAT: One page in the granite skill's component shape: `<Page>.swift` (the command, its relays, the inputs it is
//        made with), `<Page>+Center.swift` (state only its own controls touch), `<Page>+View.swift` (the layout,
//        drawn from what it shows and does: loading, empty, an error banner with a retry, pull to refresh, load
//        more, a toolbar, the first load gated on the services having loaded), `<Page>+Actions.swift` and reducers
//        when asked, and a file a subview under `Views/`.
//  PIN:  THE PAGE READS SERVICES, IT DOES NOT COPY THEM. Shared state is read as `svc.state.x` and written through
//        `svc.set(...)` or a ticketed entry; the center holds only what this page's controls touch (skill §3).
//  PIN:  EVERY WORD IS A LITERAL SWIFTUI LOCALIZES. Titles, labels, empty states and buttons are written as
//        `Text("…")`, `Button("…")`, `.navigationTitle("…")`; the `localize` agent harvests them.

import Foundation

struct ComponentEmitter {
    let spec: ComponentSpec
    /// What the page is made with: `let post Post` lines.
    let inputs: [Field]

    var type: String { spec.type }

    /// Whether a control is bound to a service's state: the page then re-draws within a frame of its own change.
    var bindsService: Bool {
        let bound = spec.labelled.map(\.expression) + [spec.show("selection"), spec.show("query"), spec.show("sidebarSelection")].compactMap { $0?.expression }
        return bound.contains { serviceField($0) != nil }
    }

    /// The services the page's controls bind to.
    var boundServices: [String] {
        let bound = spec.labelled.map(\.expression) + [spec.show("selection"), spec.show("query"), spec.show("sidebarSelection")].compactMap { $0?.expression }
        var seen: Set<String> = []
        return bound.compactMap { serviceField($0)?.relay.type }.filter { seen.insert($0).inserted }
    }

    var isModal: Bool { spec.layout == .compose }

    /// The page's files, by their path inside its folder.
    func files() -> [(path: String, text: String)] {
        var files = [("\(type).swift", component()), ("\(type)+Center.swift", center()), ("\(type)+View.swift", ComponentLayouts(emitter: self).view())]
        if !spec.actions.isEmpty { files.append(("\(type)+Actions.swift", actionsFile())) }
        for event in spec.events { files.append(("Reducers/\(type).\(event.typeName).swift", reducer(event))) }
        return files
    }

    private func header(_ modules: [String]) -> [String] {
        var seen: Set<String> = []
        return (modules + spec.imports).filter { seen.insert($0).inserted }.map { "import \($0)" } + [""]
    }

    // MARK: - The component

    func component() -> String {
        var code = Code()
        header(["Granite", "SwiftUI"]).forEach { code.line($0) }
        code.open("struct \(type): GraniteComponent {")
        code.line("@Command var center: Center")
        if !spec.relays.isEmpty { code.line() }
        for relay in spec.relays { code.line("@Relay var \(SwiftName.member(relay.name)): \(relay.type)") }
        if bindsService {
            code.line()
            code.line("/// Re-draws the page within a frame of a change to the services its controls are bound to.")
            code.line("@StateObject private var clock = RelayClock([\(boundServices.map { "RelayClock.on(\($0).self)" }.joined(separator: ", "))])")
        }
        if isModal {
            code.line()
            code.line("@Environment(\\.dismiss) var dismiss")
        }
        if !inputs.isEmpty {
            code.line()
            for input in inputs {
                if let doc = input.doc { code.line("/// \(SwiftName.sentence(doc))") }
                code.line("let \(SwiftName.member(input.name)): \(input.type)")
            }
            code.line()
            let parameters = inputs.map { "\(SwiftName.member($0.name)): \($0.type)\($0.defaultValue.map { " = \($0)" } ?? ($0.type.isOptional ? " = nil" : ""))" }
            code.scope("init(\(parameters.joined(separator: ", "))) {") { code in
                for input in inputs { code.line("self.\(SwiftName.member(input.name)) = \(SwiftName.member(input.name))") }
            }
        }
        code.close()
        return code.text
    }

    // MARK: - The center

    func center() -> String {
        var code = Code()
        header(["Foundation", "Granite"]).forEach { code.line($0) }
        code.open("extension \(type) {")
        code.line("/// State only this page's own controls touch; what another page, a menu or the root reads lives in a service.")
        code.open("struct Center: GraniteCenter {")
        if spec.fields.isEmpty {
            code.line("struct State: GraniteState {}")
        } else {
            code.scope("struct State: GraniteState {") { code in
                for field in spec.fields {
                    if let doc = field.doc { code.line("/// \(SwiftName.sentence(doc))") }
                    code.line("var \(SwiftName.member(field.name)): \(field.type)\(ServiceEmitter.initial(field).map { " = \($0)" } ?? "")")
                }
            }
        }
        code.line()
        for event in spec.events { code.line("@Event var \(event.verb): \(event.typeName).Reducer") }
        if !spec.events.isEmpty { code.line() }
        code.line("@Store var state: State")
        code.close()
        code.close()
        return code.text
    }

    // MARK: - Actions

    func actionsFile() -> String {
        var code = Code()
        header(["Foundation", "Granite", "SwiftUI"]).forEach { code.line($0) }
        code.open("extension \(type) {")
        for (index, action) in spec.actions.enumerated() {
            if index > 0 { code.line() }
            let parameters
 = action.params.map { "\(SwiftName.member($0.name)): \($0.type)" }.joined(separator: ", ")
            code.scope("func \(SwiftName.member(action.name))(\(parameters)) async throws {") { code in
                for statement in action.statements { code.line(Self.writingOwnState(statement)) }
            }
        }
        code.close()
        return code.text
    }

    /// `state.query = ""` written as the page's own state is written: `_state.query.wrappedValue = ""`.
    static func writingOwnState(_ statement: String) -> String {
        statement.replacingOccurrences(of: #"(?<![\w.])state\.(\w+)\s*=(?!=)"#, with: "_state.$1.wrappedValue =", options: .regularExpression)
    }

    // MARK: - Reducers

    func reducer(_ event: Event) -> String {
        var code = Code()
        header(["Foundation", "Granite"]).forEach { code.line($0) }
        code.open("extension \(type) {")
        if let doc = event.doc { code.line("/// \(SwiftName.sentence(doc))") }
        code.open("struct \(event.typeName): GraniteReducer {")
        code.line("typealias Center = \(type).Center")
        code.line()
        if event.params.isEmpty {
            code.line("struct Meta: GranitePayload {}")
        } else {
            code.scope("struct Meta: GranitePayload {") { code in
                for param in event.params { code.line("let \(SwiftName.member(param.name)): \(param.type)") }
            }
        }
        code.line()
        code.line("@Payload var meta: Meta?")
        code.line()
        code.scope("func reduce(state: inout Center.State) {") { code in
            code.line("guard let meta else { return }")
            for param in event.params { code.line("let \(SwiftName.member(param.name)) = meta.\(SwiftName.member(param.name))") }
            if case .replace(let field) = event.write, let expression = event.expression {
                code.line("state.\(SwiftName.member(field)) = \(expression)")
            } else if case .append(let field) = event.write, let expression = event.expression {
                code.line("state.\(SwiftName.member(field)).append(contentsOf: \(expression))")
            }
        }
        code.close()
        code.close()
        return code.text
    }

    // MARK: - Reading what the page shows

    /// `feed.state.selected` as the relay and the field it reads, when it is a service's field written by `set`.
    func serviceField(_ expression: String) -> (relay: Relay, field: String)? {
        let parts = expression.trimmingCharacters(in: .whitespaces).split(separator: ".").map(String.init)
        guard parts.count == 3, parts[1] == "state", let relay = spec.relays.first(where: { $0.name == parts[0] }),
              spec.index.isBindable(relay.type, field: parts[2]) else { return nil }
        return (relay, parts[2])
    }

    /// `state.query` as the page's own field.
    func ownField(_ expression: String) -> Field? {
        let parts = expression.trimmingCharacters(in: .whitespaces).split(separator: ".").map(String.init)
        guard parts.count == 2, parts[0] == "state" else { return nil }
        return spec.fields.first { $0.name == parts[1] }
    }

    /// A binding to what `expression` reads, when a control may write it.
    func binding(_ expression: String) -> String? {
        if let (relay, field) = serviceField(expression) {
            return "\(SwiftName.member(relay.name)).binding(\\.\(SwiftName.member(field))) { .\(SwiftName.member(field))($0) }"
        }
        if let field = ownField(expression) { return "center.$state.binding.\(SwiftName.member(field.name))" }
        return nil
    }

    /// A statement writing `value` where `expression` reads.
    func write(_ expression: String, _ value: String) -> String? {
        if let (relay, field) = serviceField(expression) { return "\(SwiftName.member(relay.name)).set(.\(SwiftName.member(field))(\(value)))" }
        if let field = ownField(expression) { return "_state.\(SwiftName.member(field.name)).wrappedValue = \(value)" }
        return nil
    }

    /// The type `expression` reads: a service's field, the page's own, or one of its inputs.
    func typeRef(_ expression: String) -> TypeRef? {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        if let input = inputs.first(where: { $0.name == trimmed }) { return input.type }
        return spec.typeRef(of: trimmed)
    }

    // MARK: - Pieces every layout shares

    /// The empty and loading states over what the page lists.
    func status(_ code: inout Code, items: String) {
        code.line()
        code.line("@ViewBuilder")
        code.scope("private var status: some View {") { code in
            code.scope("if \(items).isEmpty {") { code in
                if let loading = spec.loadingExpression {
                    code.open("if \(loading) {")
                    code.line("ProgressView()")
                    code.middle("} else {")
                    emptyView(&code)
                    code.close()
                } else {

                    emptyView(&code)
                }
            }
        }
    }

    private func emptyView(_ code: inout Code) {
        let title = SwiftName.escaped(spec.emptyTitle)
        if let message = spec.show("empty"), message.isLiteral {
            code.line("ContentUnavailableView(\(message.expression), systemImage: \"tray\")")
        } else if let message = spec.show("empty") {
            code.line("ContentUnavailableView(\"\(title)\", systemImage: \"tray\", description: Text(verbatim: \(message.expression)))")
        } else {

            code.line("ContentUnavailableView(\"\(title)\", systemImage: \"tray\")")
        }
    }

    /// A banner over the page with why the last work failed, and a retry when the page can refresh.
    func errorBanner(_ code: inout Code) {
        guard let error = spec.errorExpression else { return }
        code.line()
        code.line("@ViewBuilder")
        code.scope("private var errorBanner: some View {") { code in
            code.scope("if let message = \(error) {") { code in
                code.scope("HStack(spacing: 8) {") { code in
                    code.line("Label(message, systemImage: \"exclamationmark.triangle.fill\")")
                    code.line("    .font(.callout)")
                    code.line("Spacer(minLength: 8)")
                    if let refresh = spec.refresh {
                        code.line("Button(\"Try Again\") { \(spec.call(refresh)) }")
                        code.line("    .buttonStyle(.borderless)")
                    }
                }
                code.line(".padding(.horizontal)")
                code.line(".padding(.vertical, 8)")
                code.line(".background(.orange.opacity(0.15))")
            }
        }
    }

    /// Whether every service the page reads has loaded: the first load waits for it (skill rule 7).
    func readiness(_ code: inout Code) {
        guard spec.refresh != nil, !spec.relays.isEmpty else { return }
        code.line()
        code.line("/// Whether every service the page reads has loaded what it keeps.")
        code.line("private var isReady: Bool { \(spec.relays.map { "\(SwiftName.member($0.name)).isLoaded" }.joined(separator: " && ")) }")
    }

    /// The modifiers that end every layout: the banner, the title, refresh, the toolbar, the first load.
    func finish(_ code: inout Code, items: String?, refreshable: Bool = true) {
        if spec.errorExpression != nil { code.line(".safeAreaInset(edge: .top, spacing: 0) { errorBanner }") }
        code.line(spec.titleModifier)
        if refreshable, let refresh = spec.refresh { code.line(".refreshable { try? await \(SwiftName.member(refresh.name))() }") }
        toolbar(&code)
        if let refresh = spec.refresh, !spec.relays.isEmpty {
            code.scope(".task(id: isReady) {") { code in
                code.line(items.map { "guard isReady, \($0).isEmpty else { return }" } ?? "guard isReady else { return }")
                code.line("try? await \(SwiftName.member(refresh.name))()")
            }
        }
    }

    /// The toolbar: the page's own buttons, and on the Mac, where nothing is pulled, a refresh.
    func toolbar(_ code: inout Code, extra: [String] = []) {
        let buttons = spec.toolbarActions
        guard !buttons.isEmpty || spec.refresh != nil || !extra.isEmpty else { return }
        code.scope(".toolbar {") { code in
            for line in extra { code.block(line) }
            if let refresh = spec.refresh {
                code.line("#if os(macOS)")
                code.scope("ToolbarItem {") { code in
                    code.line("Button { \(spec.call(refresh)) } label: {")
                    code.line("    Label(\"\(SwiftName.escaped(refresh.title ?? "Refresh"))\", systemImage: \"\(refresh.symbol ?? "arrow.clockwise")\")")
                    code.line("}")
                    code.line(".keyboardShortcut(\"r\")")
                }
                code.line("#endif")
            }
            if !buttons.isEmpty {
                code.scope("ToolbarItemGroup(placement: .primaryAction) {") { code in
                    for action in buttons { code.line(button(action, item: nil)) }
                }
            }
        }
    }

    /// A button that runs `action`: its words, its symbol beside them, destructive when it takes something away.
    func button(_ action: Action, item: String?) -> String {
        let role = action.isDestructive ? ", role: .destructive" : ""
        let label = SwiftName.escaped(action.label)
        if let symbol = action.symbol {
            return "Button(\"\(label)\", systemImage: \"\(symbol)\"\(role)) { \(spec.call(action, item: item)) }"
        }
        return "Button(\"\(label)\"\(role)) { \(spec.call(action, item: item)) }"
    }
}
