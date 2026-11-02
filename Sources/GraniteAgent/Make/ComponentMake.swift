//  WHAT: `make: component`: one page, into the app's Components folder, laid out from what it shows and does; its
//        subviews' bodies from the host's model when a line describes one, from their value's fields otherwise.
//  PIN:  A PAGE READS SERVICES THAT EXIST. A relay to a service the project does not have is refused, and a page's
//        rows are bound to the service's real fields, read off its center.

import Foundation
import GraniteAgents

struct ComponentMake {
    let input: GraniteAppAgent.Input
    let workspace: Workspace
    let model: (any AgentHostModel)?
    let note: @Sendable (String) -> Void
    let yield: (GraniteFrame) -> Void

    /// Names a page already answers to.
    static let reservedActions: Set<String> = ["view", "body", "center", "state", "listeners", "id", "locate", "isLoaded", "build", "dismiss", "status", "errorBanner", "isReady", "results", "content", "clock"]

    func plan() async throws -> Plan {
        var problems: [String] = []
        var notes: [String] = []
        guard var type = input.type?.trimmingCharacters(in: .whitespaces), !type.isEmpty else {
            throw GraniteError.refused(["name the page with `type`, like `Feed`"])
        }
        if type.hasSuffix("Component"), type.count > "Component".count {
            type = String(type.dropLast("Component".count))
            notes.append("the page is named \(type): pages are named for what they are, without a suffix")
        }
        guard SwiftName.isTypeName(type) else { throw GraniteError.refused(["`\(type)` is not a type name in UpperCamelCase"]) }
        let index = ProjectIndex(root: workspace.root)

        var relays: [Relay] = []
        for line in input.relays ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let relay = try RelayLine.parse(line)
                if index.services[relay.type] == nil {
                    problems.append(RelayLine.missing(line, relay: relay, declared: index.declared))
                } else if relays.contains(where: { $0.name == relay.name }) {
                    problems.append("the relay `\(relay.name)` is named twice")
                } else {
                    relays.append(relay)
                }
            } catch { problems.append("\(error)") }
        }
        var fields: [Field] = [], inputs: [Field] = []
        for line in input.state ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            var text = line.trimmingCharacters(in: .whitespaces)
            let isInput = text.hasPrefix("let ")
            if isInput { text = String(text.dropFirst(4)) }
            do {
                let field = try FieldLine.parseField(text, in: line)
                if fields.contains(where: { $0.name == field.name }) || inputs.contains(where: { $0.name == field.name }) || relays.contains(where: { $0.name == field.name }) {
                    problems.append("`\(field.name)` is named twice among the page's state, inputs and relays")
                } else if isInput {
                    inputs.append(field)
                } else if ServiceEmitter.initial(field) == nil, !field.type.isOptional {
                    problems.append("`\(line)` needs a default (`= …`) or `?`: the page's state starts before anything is shown")
                } else {
                    fields.append(field)
                }
            } catch { problems.append("\(error)") }
        }
        var shows: [Show] = []
        for line in input.shows ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do { shows.append(try ShowLine.parse(line)) } catch { problems.append("\(error)") }
        }
        var actions: [Action] = []
        for line in input.actions ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let action = try ActionLine.parse(line)
                if Self.reservedActions.contains(action.name) {

                    problems.append("`\(action.name)` is the page's own; name the action something else")
                } else if actions.contains(where: { $0.name == action.name }) {
                    problems.append("the action `\(action.name)` is named twice")
                } else {
                    actions.append(action)
                }
            } catch { problems.append("\(error)") }
        }
        var views: [ViewSpec] = []
        for line in input.views ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let view = try ViewLine.parse(line)
                if views.contains(where: { $0.role == view.role }) { problems.append("the view `\(view.role)` is named twice") } else { views.append(view) }
            } catch { problems.append("\(error)") }
        }
        var events: [Event] = []
        for line in input.events ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let event = try EventLine.parse(line)
                if event.expression == nil || event.write == .none {
                    problems.append("a page's reducer `\(event.verb)` writes one of its own fields from an expression: `\(event.verb)(…) -> field = expression`")
                } else if let field = event.write.field, !fields.contains(where: { $0.name == field }) {
                    problems.append("`\(event.verb)` writes `\(field)`, which is not the page's own state")
                } else {
                    events.append(event)
                }
            } catch { problems.append("\(error)") }
        }

        let layout = input.layout ?? Self.inferred(shows)
        func has(_ role: String) -> Bool { shows.contains { $0.role == role } }
        switch layout {
        case .list, .grid, .search, .threePane:
            if !has("items") { problems.append("a \(layout.rawValue) page lists something: add `items = …` to shows, like `items = feed.state.posts`") }
            if layout == .threePane, !has("selection") { problems.append("a threePane page shows the selected item: add `selection = …` (a service's field, or `state.selected` with `selected String?` in state)") }
        case .detail:
            if !has("item") { problems.append("a detail page shows one item: add `item = …` to shows, like `item = feed.state.selected` or an input (`let post Post`, `item = post`)") }
        case .form, .settings, .compose:
            if !shows.contains(where: { $0.role == nil }) && actions.isEmpty {
                problems.append("a \(layout.rawValue) page has rows: add `\"Label\" = …` lines to shows, like `\"Title\" = state.title`")
            }
        case .tabs:
            if shows.filter({ $0.role == nil }).count < 2 { problems.append("a tabs page switches between views: add two or more `\"Title\" = SomeView()` lines to shows") }
        case .blank:
            if model == nil { problems.append("a blank page's body comes from the host's model, and this host has none: name a layout (list, grid, detail, form, settings, search, compose, tabs, threePane)") }
        }
        if layout == .search, !has("query"), !fields.contains(where: { $0.name == "query" }) {
            fields.append(Field(name: "query", type: .named("String"), defaultValue: "\"\"", key: nil, doc: "what the search field holds"))
        }
        if layout == .tabs, !fields.contains(where: { $0.name == "tab" }) {
            fields.append(Field(name: "tab", type: .named("Int"), defaultValue: "0", key: nil, doc: "the tab on screen"))
        }
        let placement = Placement.resolve(into: input.into, type: type, kind: "Components", workspace: workspace)
        guard problems.isEmpty else { throw GraniteError.refused(problems) }
        yield(.read(make: .component, lines: shows.count + actions.count + views.count))

        var spec = ComponentSpec(type: type, layout: layout, relays: relays, fields: fields, shows: shows, actions: actions, views: views,
                                 events: events, imports: input.imports ?? [], index: index)
        spec.imports += ModuleImports.modules(for: [shows.map(\.expression).joined(separator: " "), actions.flatMap(\.statements).joined(separator: " "),
                                                    actions.flatMap(\.params).map(\.type.description).joined(separator: " "),
                                                    views.flatMap(\.params).map(\.type).joined(separator: " "), fields.map(\.type.description).joined(separator: " ")],
                                              index: index, besides: placement.package?.target)
        spec.views += Self.implicitViews(spec, inputs: inputs)

        // Bodies the lines describe, from the host's model; the rest from the values' fields.
        let subviews = SubviewEmitter(spec: spec)
        let asker = model.map { BodyAsk(model: $0, rounds: min(max(input.rounds ?? 3, 1), 5), note: note) }
        for view in spec.views {
            if let description = view.description, let asker {
                note("asking for \(spec.viewType(view))'s body")
                let (body, rounds) = try await asker.ask(spec.viewType(view), system: BodyPrompts.view, user: Self.viewPrompt(view, spec: spec, description: description, notes: input.notes),
                                                          file: { subviews.file(view, body: $0) }, check: { _ in [] })
                spec.bodies[view.role] = body
                yield(.asked(type: spec.viewType(view), rounds: rounds))
            } else if view.description != nil {
                notes.append("\(spec.viewType(view)) is made from its values' fields: this host has no model to write the body its line describes")
            }
        }
        if layout == .blank, let asker {
            note("asking for \(type)'s page")
            let (body, rounds)
 = try await asker.ask(type, system: BodyPrompts.page, user: Self.pagePrompt(spec, notes: input.notes),
                                                      file: { body in
                                                          var probe = spec
                                                          probe.bodies["content"] = body
                                                          return ComponentLayouts(emitter: ComponentEmitter(spec: probe, inputs: inputs)).view()
                                                      }, check: { _ in [] })
            spec.bodies["content"] = body
            yield(.asked(type: type, rounds: rounds))

        }

        var plan = Plan()
        let emitter = ComponentEmitter(spec: spec, inputs: inputs)
        let role: Plan.Role = placement.package == nil ? .app : .other
        for (path, text) in emitter.files() { plan.write(placement.folder.appendingPathComponent(path), text, role: role) }
        for view in spec.views {
            let body = spec.bodies[view.role] ?? subviews.body(view)
            plan.write(placement.folder.appendingPathComponent("Views/\(type).\(view.roleName)View.swift"), subviews.file(view, body: body), role: role)
        }
        if emitter.bindsService, !index.hasRelayClock {
            let folder = placement.package.map { $0.sources.appendingPathComponent("Utility") } ?? AppLayout.detect(workspace).utility

            plan.write(folder.appendingPathComponent("RelayClock.swift"), UtilityTemplates.relayClock, role: role)
            plan.notes.append("RelayClock keeps \(type)'s bound controls up with their service within a frame")
        }
        plan.types = [type] + spec.views.map { spec.viewType($0) }
        plan.notes += notes
        if let element = spec.element, index.types[element] == nil {
            plan.notes.append("\(element)'s fields were not found in the project, so its rows show the value as text: add a `row(…)` views line with a description")
        }
        if spec.refresh != nil, !relays.isEmpty { plan.notes.append("\(type) loads once every service it reads has loaded, and refreshes when pulled (⌘R on the Mac)") }
        return plan
    }

    /// The layout the shows lines suggest when the call names none.
    static func inferred(_ shows: [Show]) -> GraniteLayout {
        if shows.contains(where: { $0.role == "items" }) { return shows.contains(where: { $0.role == "query" }) ? .search : .list }
        if shows.contains(where: { $0.role == "item" }) { return .detail }
        return .form
    }

    /// The views the layout draws that no line named: a row or a cell of the items, the item's content.
    static func implicitViews(_ spec: ComponentSpec, inputs: [Field]) -> [ViewSpec] {
        var views: [ViewSpec] = []
        let describe = Describe(index: spec.index)
        if [.list, .search, .threePane, .grid].contains(spec.layout), spec.rowView == nil, let element = spec.element, describe.title(of: element) != nil {
            views.append(ViewSpec(role: spec.layout == .grid ? "cell" : "row", params: [.init(name: spec.itemName, type: element)], description: nil))
        }
        var item: String?
        if spec.layout == .detail, let expression = spec.show("item")?.expression {
            let trimmed = expression.trimmingCharacters(in: .whitespaces)
            item = inputs.first { $0.name == trimmed }?.type.unwrapped.description ?? spec.typeRef(of: expression)?.unwrapped.description
        } else if spec.layout == .threePane {
            item = spec.element
        }
        if let item, spec.detailViews(for: item).isEmpty, describe.title(of: item) != nil {
            views.append(ViewSpec(role: "content", params: [.init(name: SwiftName.lowerFirst(item), type: item)], description: nil))
        }
        return views
    }

    static func viewPrompt(_ view: ViewSpec, spec: ComponentSpec, description: String, notes: String?) -> String {
        let properties = view.values.map { "let \($0.name): \($0.type)" } + view.closures.map { "var \($0.name): (\($0.type))? = nil" }
        var lines = ["View: struct \(spec.viewType(view)): View { \(properties.joined(separator: "; ")) }"]
        var mentioned = Set(view.values.flatMap { ((try? FieldLine.parseType($0.type, in: $0.type))?.names) ?? [] })
        for name in mentioned { mentioned.formUnion(spec.index.types[name]?.fields.flatMap { ((try? FieldLine.parseType($0.type, in: $0.type))?.names) ?? [] } ?? []) }
        for name in mentioned.sorted() {
            guard let info = spec.index.types[name] else { continue }
            lines.append("\(name): " + (info.kind == "enum" ? info.cases.joined(separator: " | ") : info.fields.map { "\($0.name) \($0.type)" }.joined(separator: ", ")))
        }
        lines.append("What it shows: \(description)")
        if let notes, !notes.isEmpty { lines.append("About the app: \(notes)") }
        lines.append("Write the body, for this app, in its own names.")
        return lines.joined(separator: "\n")
    }

    static func pagePrompt(_ spec: ComponentSpec, notes: String?) -> String {
        var lines: [String] = []
        for relay in spec.relays {
            if let service = spec.index.services[relay.type] {
                lines.append("Relay \(relay.name): \(relay.type) (state: \(service.fields.map { "\($0.name) \($0.type)" }.joined(separator: ", ")))")
            }
        }
        if !spec.fields.isEmpty { lines.append("The page's state: " + spec.fields.map { "\($0.name) \($0.type)" }.joined(separator: ", ")) }
        for view in spec.views {
            lines.append("Subview: \(spec.viewType(view))(\(view.values.map { "\($0.name): \($0.type)" }.joined(separator: ", ")))")
        }
        for action in spec.actions {
            lines.append("Action: \(action.name)(\(action.params.map { "\($0.name): \($0.type)" }.joined(separator: ", "))) async throws")
        }
        for show in spec.shows { lines.append("Shows: \(show.role ?? "row") = \(show.expression)") }
        lines.append("What it shows: \(notes ?? SwiftName.title(spec.type))")
        lines.append("Write the body, for this app, in its own names.")
        return lines.joined(separator: "\n")
    }
}
