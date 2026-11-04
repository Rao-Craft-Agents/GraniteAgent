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
        // A page named as a package's type shadows it in the app (Margin, 2026-11-01: a `PostPage` page beside
        // MarginKit's `PostPage`, the page of posts its client answers).
        if let module = index.modules[type], index.components[type] == nil {
            problems.append("`\(type)` is \(module)'s type: name the page something else, like `\(type.hasSuffix("Page") ? String(type.dropLast(4)) + "Detail" : type + "Page")`")
        }

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
        // What an action reaches through a relay is the service's: its entries, `set`, `binding`, `state`, `isLoaded`.
        for action in actions {
            problems += Self.relayMisuse(in: action.statements.joined(separator: "\n"), relays: relays, index: index).map { "`\(action.name)`: " + $0 }
            problems += Self.unseen(in: action.statements.joined(separator: "\n"), relays: relays, actions: actions.map(\.name),
                                    names: (fields + inputs + action.params).map(\.name), index: index).map { "`\(action.name)`: " + $0 }
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
            // A list of a service's field that no action loads stays empty (Margin, 2026-11-01: a Feed with no actions
            // showed "No posts yet" on a full mock backend). Name the work that would load it.
            if let items = shows.first(where: { $0.role == "items" }),
               let match = items.expression.range(of: #"^\s*([a-z]\w*)\.state\.\w+"#, options: .regularExpression),
               let relayName = items.expression[match].split(separator: ".").first.map(String.init),
               let relay = relays.first(where: { $0.name == relayName }), let service = index.services[relay.type] {
                let work = service.signatures.filter { !$0.contains("func set(") && !$0.contains("func binding") }
                let entries = service.entries.filter { !["set", "binding"].contains($0) }
                let loads = actions.contains { action in entries.contains { entry in action.statements.contains { $0.contains("\(relayName).\(entry)(") } } }
                if !work.isEmpty, !loads {
                    problems.append("`\(items.expression)` is loaded by nothing on this page: add a `refresh` action that loads it, "
                                    + "from \(relay.type)'s work (" + work.prefix(4).map { "`\($0)`" }.joined(separator: "; ") + ")")
                }
            }
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
            if model == nil, input.body == nil { problems.append("a blank page's body comes from `body` or the host's model, and this host has none: give `body`, or name a layout (list, grid, detail, form, settings, search, compose, tabs, threePane)") }
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
                                                          file: { subviews.file(view, body: $0) }, check: { Self.unknownNames(in: $0, spec: spec, view: view) })
                spec.bodies[view.role] = body
                yield(.asked(type: spec.viewType(view), rounds: rounds))
            } else if view.description != nil {
                notes.append("\(spec.viewType(view)) is made from its values' fields: this host has no model to write the body its line describes")
            }
        }
        if layout == .blank, let given = input.body?.trimmingCharacters(in: .whitespacesAndNewlines), !given.isEmpty {
            // The body as the call wrote it: parsed in its file, never asked of the model.
            var probe = spec
            probe.bodies["content"] = given
            if let failure = BodyAsk.parse(ComponentLayouts(emitter: ComponentEmitter(spec: probe, inputs: inputs)).view()) {
                throw GraniteError.refused(["the page's `body` does not parse: \(failure)"])
            }
            // The rule a body asked of the model is held to, for one given in the call too.
            let unknown = Self.unknownNames(in: given, spec: spec, view: nil)
            if !unknown.isEmpty { throw GraniteError.refused(unknown.map { "the page's `body`: \($0)" }) }
            spec.bodies["content"] = given
        } else if layout == .blank, let asker {
            note("asking for \(type)'s page")
            let (body, rounds)
 = try await asker.ask(type, system: BodyPrompts.page, user: Self.pagePrompt(spec, notes: input.notes),
                                                      file: { body in
                                                          var probe = spec
                                                          probe.bodies["content"] = body
                                                          return ComponentLayouts(emitter: ComponentEmitter(spec: probe, inputs: inputs)).view()
                                                      }, check: { Self.unknownNames(in: $0, spec: spec, view: nil) })
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
        let shapes = Self.shapes(named: description + " " + (notes ?? ""), index: spec.index)
        if !shapes.isEmpty { lines.append("The app's types it names, as declared (use exactly these initializers, cases and members):\n" + shapes) }
        lines.append("Write the body, for this app, in its own names.")
        return lines.joined(separator: "\n")
    }

    /// SwiftUI's and Foundation's types a body is likely to make, beside the app's own.
    static let knownTypes: Set<String> = [
        "Text", "Image", "Label", "Button", "Link", "Menu", "Toggle", "Picker", "Slider", "Stepper", "TextField", "SecureField",
        "TextEditor", "DatePicker", "ColorPicker", "ProgressView", "Gauge", "VStack", "HStack", "ZStack", "LazyVStack", "LazyHStack",
        "LazyVGrid", "LazyHGrid", "Grid", "GridRow", "GridItem", "List", "ForEach", "Section", "Form", "Group", "GroupBox", "ScrollView",
        "ScrollViewReader", "GeometryReader", "Spacer", "Divider", "Color", "LinearGradient", "RadialGradient", "AngularGradient",
        "Rectangle", "RoundedRectangle", "Circle", "Capsule", "Ellipse", "UnevenRoundedRectangle", "AsyncImage", "NavigationStack",
        "NavigationLink", "NavigationSplitView", "TabView", "ContentUnavailableView", "ShareLink", "EmptyView", "AnyView", "ViewThatFits",
        "Font", "Edge", "EdgeInsets", "CGSize", "CGFloat", "CGPoint", "Angle", "Animation", "Binding", "LocalizedStringKey",
        "String", "Int", "Double", "Bool", "Date", "URL", "UUID", "Array", "Dictionary", "Set", "Optional", "Task", "Text.DateStyle",
        "Material", "ShapeStyle", "AnyShapeStyle", "RelativeDateTimeFormatter", "DateFormatter", "NumberFormatter", "Calendar",
    ]

    /// Names a body uses that neither SwiftUI nor the app has: a view it makes (`Spinner()`), or work it awaits that
    /// is not one of the page's actions (`await refresh()` on a page with no refresh). Margin, 2026-11-01: bodies
    /// made a `Spinner` and awaited a `refresh` the page did not have, and did not build.
    /// Each `relay.member` in `text` that its service does not have: an entry it does not declare (`feed.load()` when
    /// FeedService has `loadFeed`), or its state read without `.state` (`feed.lastError`). Margin, 2026-11-01.
    static func relayMisuse(in text: String, relays: [Relay], index: ProjectIndex) -> [String] {
        var problems: [String] = []
        for relay in relays {
            guard let service = index.services[relay.type] else { continue }
            let own: Set<String> = Set(service.entries).union(["set", "binding", "state", "isLoaded", "center", "preload", "restore"])
            var seen: Set<String> = []
            for member in text.matches(#"(?<![\w.])\#(relay.name)\.([A-Za-z_]\w*)"#) where !own.contains(member) && seen.insert(member).inserted {
                if service.field(member) != nil {
                    problems.append("`\(relay.name).\(member)` is \(relay.type)'s state: read it as `\(relay.name).state.\(member)`")
                } else {
                    let entries = service.entries.filter { !["set", "binding"].contains($0) }
                    // PIN: say how to add it. Told only "FeedService has no `load`" of a service with no work at all, the
                    // model wrote the pages by hand rather than give the service its work first (Margin c6, 2026-11-02).
                    let base = relay.type.hasSuffix("Service") ? String(relay.type.dropLast("Service".count)) : relay.type
                    let add = "give it one first: `make: service`, `type: \(base)`, `events: [\"\(member)(…) -> … = …\"]`"
                    problems.append("\(relay.type) has no `\(member)`"
                                    + (entries.isEmpty ? "; it has no work yet: " + add
                                       : ": its work is " + entries.map { "`\($0)(…)`" }.joined(separator: ", ") + "; to add `\(member)`, " + add))
                }
            }
        }
        return problems
    }

    /// What an action can reach: the page's relays, its actions, its state and inputs, and the language's own words.
    static let actionWords: Set<String> = [
        "try", "await", "let", "var", "if", "guard", "else", "return", "self", "true", "false", "nil", "in", "case", "switch",
        "for", "while", "do", "catch", "throw", "is", "as", "some", "any", "state", "center", "withAnimation", "print", "max", "min",
        "abs", "zip", "stride", "dismiss", "openURL", "openWindow", "defer", "where",
    ]

    /// Each name an action calls or starts from that the page cannot see: `loadFeed(…)` when the work is the relay's
    /// (`feed.load(…)`), or `modals.…` with no `modals` relay. Margin c7, 2026-11-02: both were written into the page
    /// and the app did not build.
    static func unseen(in text: String, relays: [Relay], actions: [String], names: [String], index: ProjectIndex) -> [String] {
        let code = text.replacingOccurrences(of: #""(?:[^"\\]|\\.)*""#, with: "\"\"", options: .regularExpression)
        // Names the statements bind themselves: `let x`, `for x in`, a closure's `{ a, b in`.
        let bound = code.matches(#"(?:let|var|for)\s+([a-z_][A-Za-z0-9_]*)"#)
            + code.matches(#"\{\s*([A-Za-z0-9_,\s]+?)\s+in\b"#).flatMap { $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        let seen = Set(relays.map(\.name) + actions + names + bound).union(actionWords)
        var problems: [String] = [], said: Set<String> = []
        for name in code.matches(#"(?<![\w.$])([a-z_][A-Za-z0-9_]*)\s*[(.]"#) where !seen.contains(name) && said.insert(name).inserted {
            let called = code.range(of: #"(?<![\w.$])"# + name + #"\s*\("#, options: .regularExpression) != nil
            if called {
                // The relays whose work this might be: an entry with the same name, or one the name ends with.
                let owners = relays.compactMap { relay -> String? in
                    guard let entries = index.services[relay.type]?.entries.filter({ !["set", "binding"].contains($0) }) else { return nil }
                    let hit = entries.first { $0 == name } ?? entries.first { name.lowercased().hasPrefix($0.lowercased()) }
                    return hit.map { "`\(relay.name).\($0)(…)`" }
                }
                // A relay whose service has no work yet: say to give it the work first, named after the call.
                let idle = relays.first { relay in (index.services[relay.type]?.entries ?? []).allSatisfy { ["set", "binding"].contains($0) } }
                let work = name.range(of: #"^[a-z]+"#, options: .regularExpression).map { String(name[$0]) } ?? name
                let fallback = idle.map { relay -> String in
                    let base = relay.type.hasSuffix("Service") ? String(relay.type.dropLast("Service".count)) : relay.type
                    return "\(relay.type) has no work yet: give it `\(work)` first (`make: service`, `type: \(base)`, "
                        + "`events: [\"\(work)(…) -> … = …\"]`), then call `\(relay.name).\(work)(…)`"
                } ?? "its work is a relay's (`relayName.work(…)`) or another action"
                problems.append("`\(name)(…)` is not something the page can call: "
                                + (owners.isEmpty ? fallback : "call " + owners.joined(separator: " or ")))
            } else {
                let services = index.services.keys.sorted()
                let match = services.first { $0.lowercased().hasPrefix(name.lowercased().hasSuffix("s") ? String(name.dropLast()).lowercased() : name.lowercased()) }
                problems.append("`\(name)` is not one of the page's relays" + (match.map { ": add it to `relays` (`\(name): \($0)`)" }
                                ?? ", and no service is called that: add the relay, or make the service first"))
            }
        }
        return problems
    }

    static func unknownNames(in body: String, spec: ComponentSpec, view: ViewSpec?) -> [String] {
        var problems = Self.relayMisuse(in: body, relays: spec.relays, index: spec.index)
        // The app's types, and what this call makes: the page and its subviews.
        let declared = spec.index.declared.union(spec.index.shapes.keys).union(spec.views.map { spec.viewType($0) }).union([spec.type])
        var made: [String] = []
        for name in body.matches(#"(?<![\w.])([A-Z][A-Za-z0-9_]*)\s*(?:<[^>]*>)?\s*\("#) where !made.contains(name) {
            if !knownTypes.contains(name) && !declared.contains(name) { made.append(name) }
        }
        if !made.isEmpty {
            problems.append(made.map { "`\($0)`" }.joined(separator: ", ") + " \(made.count == 1 ? "is" : "are") not a view SwiftUI or this app has: use one that is (ProgressView for a spinner)")
        }
        if view == nil {
            let actions = Set(spec.actions.map { SwiftName.member($0.name) })
            var awaited: [String] = []
            for name in body.matches(#"await\s+([a-z]\w*)\s*\("#) where !actions.contains(name) && !awaited.contains(name) { awaited.append(name) }
            if !awaited.isEmpty {
                problems.append(awaited.map { "`\($0)()`" }.joined(separator: ", ") + " is not one of the page's actions"
                                + (actions.isEmpty ? "" : " (it has " + actions.sorted().map { "`\($0)()`" }.joined(separator: ", ") + ")"))
            }
        }
        return problems
    }

    /// The shapes of the app's types `text` names, and of the types those shapes name in turn: a page that
    /// shows `FeedView` is told its initializer, `SocialActions`' closures and `SocialTarget`'s cases (Hearth,
    /// 2026-11-01: a body written without them read `target.post` and passed a String for a `SocialVote`).
    static func shapes(named text: String, index: ProjectIndex, budget: Int = 3_600) -> String {
        func words(_ text: String) -> [String] {
            var seen: [String] = []
            for match in text.matches(#"\b([A-Z][A-Za-z0-9_]*)\b"#) where index.shapes[match] != nil && !seen.contains(match) { seen.append(match) }
            return seen
        }
        var names = words(text), next = 0
        // The types those shapes name, and theirs in turn: FeedView names SocialActions, which names SocialTarget.
        while next < names.count, names.count < 12 {
            for more in words((index.shapes[names[next]] ?? []).joined(separator: " ")) where !names.contains(more) { names.append(more) }
            next += 1
        }
        var out: [String] = [], used = 0
        for name in names {
            let block = (index.shapes[name] ?? []).enumerated().map { $0.offset == 0 ? $0.element : "    " + $0.element }.joined(separator: "\n")
            guard used + block.count <= budget else { continue }
            out.append(block); used += block.count
        }
        return out.joined(separator: "\n")
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
        if !spec.actions.isEmpty {
            lines.append("The page's own functions, in \(spec.type)+Actions.swift: call them as they are, never declare them again:")
            for action in spec.actions {
                lines.append("  func \(SwiftName.member(action.name))(\(action.params.map { "\(SwiftName.member($0.name)): \($0.type)" }.joined(separator: ", "))) async throws")
            }
        }
        for show in spec.shows { lines.append("Shows: \(show.role ?? "row") = \(show.expression)") }
        lines.append("What it shows: \(notes ?? SwiftName.title(spec.type))")
        let shapes = Self.shapes(named: (notes ?? "") + " " + spec.shows.map(\.expression).joined(separator: " "), index: spec.index)
        if !shapes.isEmpty { lines.append("The app's types it names, as declared (use exactly these initializers, cases and members):\n" + shapes) }
        lines.append("Write the body, for this app, in its own names.")
        return lines.joined(separator: "\n")
    }
}
