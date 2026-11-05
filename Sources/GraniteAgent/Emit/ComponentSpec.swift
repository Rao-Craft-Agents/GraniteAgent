//  WHAT: One page as a call describes it, read against the project: what the page lists and of which type, which
//        relay is its primary service, which action refreshes it, loads more, opens an item, sends a form, and which
//        subview draws a row. `ComponentEmitter` writes from it.

import Foundation

struct ComponentSpec {
    var type: String
    var layout: GraniteLayout
    var relays: [Relay]
    /// The page's own view state.
    var fields: [Field]
    var shows: [Show]
    var actions: [Action]
    var views: [ViewSpec]
    var events: [Event] = []
    var imports: [String] = []
    var index: ProjectIndex
    /// The bodies the host's model wrote, by view role; `content` for a blank page.
    var bodies: [String: String] = [:]

    func show(_ role: String) -> Show? { shows.first { $0.role == role } }

    var labelled: [Show] { shows.filter { if case .label = $0.key { return true } else { return false } } }

    func action(_ name: String) -> Action? { actions.first { $0.name == name } }

    // MARK: - What the page lists

    /// The type an expression reads, as written: a relay's state field, or the page's own.
    func typeText(of expression: String) -> String? { index.type(of: expression, relays: relays, own: fields) }

    func typeRef(of expression: String) -> TypeRef? {
        guard let text = typeText(of: expression) else { return nil }
        return try? FieldLine.parseType(text, in: text)
    }

    /// The element type of `items` (`[Post]` → `Post`), when the project says what it is.
    var element: String? { show("items").flatMap { typeRef(of: $0.expression)?.element?.unwrapped.description } }

    /// The variable an item is bound to in a loop: `Post` → `post`.
    var itemName: String {
        guard let element, let last = element.split(separator: ".").last else { return "item" }
        let name = SwiftName.lowerFirst(String(last))
        return SwiftName.keywords.contains(name) || relays.contains(where: { $0.name == name }) || fields.contains(where: { $0.name == name }) ? "item" : name
    }

    /// Whether items are `Identifiable`: `ForEach(items)`, or else `ForEach(items, id: \.self)`.
    /// PIN: THE STANDARD VALUES ARE NEVER IDENTIFIABLE. A `[String]` or `[URL]` of state is drawn by `id: \.self`
    /// (they are all Hashable); a type the project does not declare (a package's model) is taken to be Identifiable.
    var elementIsIdentifiable: Bool {
        guard let element else { return true }
        if Self.standardValues.contains(element) { return false }
        guard let info = index.types[element] else { return true }
        return info.conformances.contains("Identifiable")
    }

    /// The standard library's and Foundation's value types: Hashable, never Identifiable.
    static let standardValues: Set<String> = ["String", "Substring", "Character", "Bool", "Int", "Int8", "Int16", "Int32", "Int64",
                                              "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "Double", "Float", "CGFloat",
                                              "Decimal", "Date", "URL", "UUID", "Data"]

    /// The relay the page is about: the one its items, or else its first relay, read.
    var primary: Relay? {
        if let items = show("items")?.expression ?? show("item")?.expression,
           let name = items.split(separator: ".").first, let relay = relays.first(where: { $0.name == name }) { return relay }
        return relays.first
    }

    /// Whether the primary relay is a service of this family's shape (it has `loading` and `lastError`).
    var primaryHasStatus: Bool {
        guard let primary, let service = index.services[primary.type] else { return false }
        return service.field("loading") != nil && service.field("lastError") != nil
    }

    var loadingExpression: String? {
        if let show = show("loading") { return show.expression }
        guard primaryHasStatus, let primary else { return nil }
        return "\(primary.name).state.loading != nil"
    }

    var errorExpression: String? {
        if let show = show("error") { return show.expression }
        guard primaryHasStatus, let primary else { return nil }
        return "\(primary.name).state.lastError"
    }

    /// The navigation title: a literal SwiftUI localizes, or an expression shown as it is.
    var titleModifier: String {
        if let show = show("title") { return ".navigationTitle(\(show.expression))" }

        return ".navigationTitle(\"\(SwiftName.escaped(SwiftName.title(type)))\")"
    }

    /// "No Posts", from the field the items are.
    var emptyTitle: String {
        guard let items = show("items")?.expression, let last = items.split(separator: ".").last else { return "Nothing Here" }
        return "No " + SwiftName.title(String(last))
    }

    // MARK: - What the actions do

    var refresh: Action? { action("refresh").flatMap { $0.params.isEmpty ? $0 : nil } }
    var more: Action? { action("more").flatMap { $0.params.isEmpty ? $0 : nil } }
    var submit: Action? { action("submit") ?? action("send") ?? action("save") ?? action("post") }
    var search: Action? { action("search") }

    /// The action a tap on an item runs: `open(post Post)` or `select(post Post)`.
    var open: Action? {
        ["open", "select", "show"].compactMap { action($0) }.first { $0.params.count == 1 && $0.params[0].type.description == element }
    }

    /// The views a closure of which an action of the same name fills.
    func wires(_ action: Action) -> Bool { views.contains { $0.closures.contains { $0.name == action.name } } }

    /// Actions on one item, beside opening it: a row's context menu and its swipe.
    var itemActions: [Action] {
        guard let element else { return [] }
        return actions.filter { action in
            action.name != open?.name && !wires(action) && action.params.count == 1 && action.params[0].type.description == element
        }
    }

    /// Actions that take nothing and are not the page's refresh, load-more, send or search: toolbar buttons.
    var toolbarActions: [Action] {
        let special = Set([refresh?.name, more?.name, submit?.name, search?.name, "cancel"].compactMap { $0 })
        return actions.filter { $0.params.isEmpty && !special.contains($0.name) && !wires($0) }
    }

    // MARK: - Subviews

    /// The view that draws one item: the views line that takes the element, `row`/`cell`/`card` first.
    var rowView: ViewSpec? {
        guard let element else { return views.first { ["row", "cell", "card"].contains($0.role) } }
        let taking = views.filter { $0.values.count == 1 && $0.values[0].type == element }
        return taking.first { ["row", "cell", "card", "item"].contains($0.role) } ?? taking.first
    }

    /// Views that show the item on a detail page, in the order given.
    func detailViews(for element: String?) -> [ViewSpec] {
        guard let element else { return [] }
        return views.filter { view in view.values.contains { $0.type == element } && view.role != rowView?.role }
    }

    /// Views whose values the shows lines give: placed above what the page lists.
    var headerViews: [ViewSpec] {
        views.filter { view in
            view != rowView && !(element.map { e in view.values.contains { $0.type == e } } ?? false)
                && view.values.allSatisfy { value in show(value.name) != nil }
        }
    }

    /// `FeedRowView`.
    func viewType(_ view: ViewSpec) -> String { "\(type)\(view.roleName)View" }

    /// The view drawn for `item` (of `itemType`, the items' element when left out): its values from the item and the
    /// shows lines, and under it the routes of what it sends, each to the action of its name.
    func instance(_ view: ViewSpec, item: String?, itemType: String? = nil) -> String {
        var arguments: [String] = []
        var routes: [String] = []
        let element = itemType ?? self.element
        for param in view.params {
            if param.isClosure {
                guard let action = action(param.name), let route = route(view, param, to: action, item: item, itemType: element) else { continue }
                routes.append(route)
            } else if let element, param.type == element, let item {

                arguments.append("\(SwiftName.member(param.name)): \(item)")
            } else if let show = show(param.name) {
                arguments.append("\(SwiftName.member(param.name)): \(show.expression)")
            }
        }
        let drawn = "\(viewType(view))(\(arguments.joined(separator: ", ")))"
        guard !routes.isEmpty else { return drawn }
        return ([drawn, "    .onBubble {"] + routes.map { "        " + $0 } + ["    }"]).joined(separator: "\n")
    }

    /// The route a view's `param` comes up by: it runs `action`, with the item first when the action takes it, and
    /// what the view sent after. Nil when the action does not take what the closure carries.
    func route(_ view: ViewSpec, _ param: ViewSpec.Param, to action: Action, item: String?, itemType: String? = nil) -> String? {
        let inputs = Self.closureInputs(param.type)
        var actionParams = action.params
        var leading: [String] = []
        if let item, let first = actionParams.first, first.type.description == (itemType ?? element) {

            leading = ["\(SwiftName.member(first.name)): \(item)"]
            actionParams.removeFirst()
        }
        guard actionParams.count == inputs.count else { return nil }
        let names = actionParams.map { SwiftName.member($0.name) }
        let call = "\(SwiftName.member(action.name))(\((leading + names.map { "\($0): \($0)" }).joined(separator: ", ")))"
        let constant = ViewBubble.constant(viewType(view), param)
        guard let payload = ViewBubble.payload(param) else {
            return "On(.\(constant)) { Task { try? await \(call) } }"
        }
        let head = names.count == 1 ? names[0] : "(" + names.joined(separator: ", ") + ")"
        return "On(.\(constant), \(payload).self) { \(head) in Task { try? await \(call) } }"
    }

    /// The closures of `view` no action of this page routes: drawn, and doing nothing when used.
    func unrouted(_ view: ViewSpec) -> [String] {
        view.closures.filter { closure in
            guard let action = action(closure.name) else { return true }
            let inputs = Self.closureInputs(closure.type).count
            return action.params.count != inputs && action.params.count != inputs + 1
        }.map(\.name)
    }

    /// `(Bool, String) -> Void` → `["Bool", "String"]`.
    static func closureInputs(_ type: String) -> [String] {
        let text = type.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@escaping", with: "").trimmingCharacters(in: .whitespaces)
        guard text.hasPrefix("("), let close = EventLine.closingParenthesis(text) else { return [] }
        let inside = String(text[text.index(after: text.startIndex)..<close]).trimmingCharacters(in: .whitespaces)
        return inside.isEmpty || inside == "Void" ? [] : LineSplit.top(inside, on: ",")
    }

    /// A call of `action` from a button: its arguments named after its parameters, which must be in scope.
    func call(_ action: Action, item: String? = nil) -> String {
        let arguments = action.params.enumerated().map { index, param -> String in
            let value = index == 0 && item != nil ? item! : SwiftName.member(param.name)
            return "\(SwiftName.member(param.name)): \(value)"
        }
        return "Task { try? await \(SwiftName.member(action.name))(\(arguments.joined(separator: ", "))) }"
    }
}
