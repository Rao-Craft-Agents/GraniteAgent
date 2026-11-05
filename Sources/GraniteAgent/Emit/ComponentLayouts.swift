//  WHAT: A page's `+View`, one layout each: a list (rows, pull to refresh, load more, a context menu and swipes per
//        item), a grid of cells, one item's detail, a search, tabs, a sidebar beside a list beside a detail, a page
//        whose body the host's model wrote, and the form family (form, settings, compose) in `FormLayout`.

import Foundation

struct ComponentLayouts {
    let emitter: ComponentEmitter
    var spec: ComponentSpec { emitter.spec }

    func view() -> String {
        var code = Code()
        var modules = ["Granite", "SwiftUI"]
        modules += spec.imports
        var seen: Set<String> = []
        for module in modules where seen.insert(module).inserted { code.line("import \(module)") }
        code.line()
        code.open("extension \(spec.type): View {")
        switch spec.layout {
        case .list: list(&code)
        case .grid: grid(&code)
        case .detail: detail(&code)
        case .search: search(&code)
        case .tabs: tabs(&code)
        case .threePane: threePane(&code)
        case .blank: blank(&code)
        case .form, .settings, .compose: FormLayout(emitter: emitter).body(&code)
        }
        code.close()
        return code.text
    }

    // MARK: - A list

    private func list(_ code: inout Code) {
        let items = spec.show("items")?.expression ?? "[]"
        let item = spec.itemName
        code.open("var view: some View {")
        code.open("List {")
        for header in spec.headerViews {
            code.block(spec.instance(header, item: nil))
            code.line("    .listRowSeparator(.hidden)")
        }
        code.open(forEach(items, item))
        row(&code, items: items, item: item, isList: true)
        code.close()
        code.close()
        code.line(".listStyle(.plain)")
        code.line(".overlay { status }")
        emitter.finish(&code, items: items)
        code.close()
        helpers(&code, items: items)
    }

    // MARK: - A grid

    private func grid(_ code: inout Code) {
        let items = spec.show("items")?.expression ?? "[]"
        let item = spec.itemName
        code.open("var view: some View {")
        code.open("ScrollView {")
        for header in spec.headerViews { code.block(spec.instance(header, item: nil)) }
        code.open("LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {")
        code.open(forEach(items, item))
        row(&code, items: items, item: item, isList: false)
        code.close()
        code.close()
        code.line(".padding()")
        code.close()
        code.line(".overlay { status }")
        emitter.finish(&code, items: items)
        code.close()
        helpers(&code, items: items)
    }

    private func forEach(_ items: String, _ item: String) -> String {
        spec.elementIsIdentifiable ? "ForEach(\(items)) { \(item) in" : "ForEach(\(items), id: \\.self) { \(item) in"
    }

    /// One item: its view, a tap that opens or selects it, its own actions, and loading more at the last one.
    private func row(_ code: inout Code, items: String, item: String, isList: Bool) {
        if let view = spec.rowView {
            code.block(spec.instance(view, item: item))
        } else {
            code.line("Text(String(describing: \(item)))")
        }

        var modifiers
: [String] = []
        let selection = spec.show("selection").map(\.expression)
        let identity = spec.elementIsIdentifiable ? "\(item).id" : item
        if spec.open != nil || selection != nil {
            var taps: [String] = []
            if let selection, let write = emitter.write(selection, identity) { taps.append(write) }
            if let open = spec.open { taps.append(spec.call(open, item: item)) }
            if !taps.isEmpty {
                modifiers.append(".contentShape(Rectangle())")
                modifiers.append(".onTapGesture { \(taps.joined(separator: "; ")) }")
                modifiers.append(".accessibilityAddTraits(.isButton)")

            }
            if let selection, isList {
                modifiers.append(".listRowBackground(\(selection) == \(identity) ? Color.accentColor.opacity(0.12) : nil)")
            }
        }
        for line in modifiers { code.line("    " + line) }
        let actions = spec.itemActions
        if !actions.isEmpty {
            code.line("    .contextMenu {")
            for action in actions { code.line("        " + emitter.button(action, item: item)) }
            code.line("    }")
            if isList {
                code.line("    #if os(iOS)")
                code.line("    .swipeActions {")
                for action in actions.sorted(by: { $0.isDestructive && !$1.isDestructive }) { code.line("        " + emitter.button(action, item: item)) }
                code.line("    }")
                code.line("    #endif")
            }
        }
        if let more = spec.more {
            var last = spec.elementIsIdentifiable ? "\(item).id == \(items).last?.id" : "\(item) == \(items).last"
            // One page at a time: the last row appearing again while a page loads asks for nothing.
            if spec.primaryHasStatus, let primary = spec.primary { last += ", \(SwiftName.member(primary.name)).state.loading == nil" }

            code.line("    .onAppear {")
            code.line("        if \(last) { \(spec.call(more)) }")
            code.line("    }")
        }
    }

    private func helpers(_ code: inout Code, items: String) {
        emitter.status(&code, items: items)
        emitter.errorBanner(&code)
        emitter.readiness(&code)
    }

    // MARK: - One item

    private func detail(_ code: inout Code) {
        let itemExpression = spec.show("item")?.expression ?? "nil"
        let type = emitter.typeRef(itemExpression)
        let element = type?.unwrapped.description
        let plain = itemExpression.range(of: #"^[a-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
        let name = plain ? itemExpression : (element.map { SwiftName.lowerFirst(String($0.split(separator: ".").last ?? Substring($0))) } ?? "item")
        let views = spec.detailViews(for: element)
        code.open("var view: some View {")
        if type?.isOptional == false && plain {
            detailBody(&code, name: name, element: element, views: views)
        } else if type?.isOptional == false {
            code.open("Group {")
            code.line("let \(name) = \(itemExpression)")
            detailBody(&code, name: name, element: element, views: views)
            code.close()
        } else {
            code.open("Group {")
            code.open("if let \(name) = \(itemExpression) {")
            detailBody(&code, name: name, element: element, views: views)
            code.middle("} else {")
            let description = spec.show("empty").map { $0.isLiteral ? ", description: Text(\($0.expression))" : ", description: Text(verbatim: \($0.expression))" } ?? ""
            code.line("ContentUnavailableView(\"Nothing Selected\", systemImage: \"doc.text.magnifyingglass\"\(description))")
            code.close()
            code.close()
        }
        if spec.errorExpression != nil { code.line(".safeAreaInset(edge: .top, spacing: 0) { errorBanner }") }
        code.line(spec.titleModifier)
        emitter.toolbar(&code)
        if let refresh = spec.refresh, !spec.relays.isEmpty {
            code.scope(".task(id: isReady) {") { code in
                code.line("guard isReady else { return }")
                code.line("try? await \(SwiftName.member(refresh.name))()")
            }
        }
        code.close()
        emitter.errorBanner(&code)
        emitter.readiness(&code)
    }

    private func detailBody(_ code: inout Code, name: String, element: String?, views: [ViewSpec]) {
        code.open("ScrollView {")
        code.open("VStack(alignment: .leading, spacing: 16) {")
        for header in spec.headerViews { code.block(spec.instance(header, item: nil)) }
        if views.isEmpty {
            code.line("Text(String(describing: \(name)))")
        } else {
            for view in views { code.block(spec.instance(view, item: name, itemType: element)) }
        }
        code.close()
        code.line(".padding()")
        code.line(".frame(maxWidth: .infinity, alignment: .leading)")
        code.close()
        let actions = element.map { e in spec.actions.filter { $0.params.count == 1 && $0.params[0].type.description == e && !spec.wires($0) } } ?? []
        if !actions.isEmpty {
            code.scope(".toolbar {") { code in
                code.scope("ToolbarItemGroup(placement: .secondaryAction) {") { code in
                    for action in actions { code.line(emitter.button(action, item: name)) }
                }
            }
        }
    }

    // MARK: - A search

    private func search(_ code: inout Code) {
        let items = spec.show("items")?.expression ?? "[]"
        let item = spec.itemName
        let query = spec.show("query")?.expression ?? "state.query"
        let binding = emitter.binding(query) ?? "center.$state.binding.query"
        code.open("var view: some View {")
        code.open("List {")
        code.open(forEach(items, item))
        row(&code, items: items, item: item, isList: true)
        code.close()
        code.close()
        code.line(".listStyle(.plain)")
        code.line(".overlay { results }")
        code.line(".searchable(text: \(binding), prompt: Text(\"Search\"))")
        if let search = spec.search {
            let call = searchCall(search, query: query)
            code.line(".onSubmit(of: .search) { Task { try? await \(call) } }")
            code.scope(".task(id: \(query)) {") { code in
                code.line("guard !\(query).isEmpty else { return }")
                code.line("// Searches once the typing settles, not on every key.")
                code.line("try? await Task.sleep(nanoseconds: 300_000_000)")
                code.line("guard !Task.isCancelled else { return }")
                code.line("try? await \(call)")
            }
        }
        if spec.errorExpression != nil { code.line(".safeAreaInset(edge: .top, spacing: 0) { errorBanner }") }
        code.line(spec.titleModifier)
        emitter.toolbar(&code)
        code.close()
        code.line()
        code.line("@ViewBuilder")
        code.scope("private var results: some View {") { code in
            code.scope("if \(items).isEmpty {") { code in
                code.open("if \(query).isEmpty {")
                let description = spec.show("empty").map { $0.isLiteral ? ", description: Text(\($0.expression))" : ", description: Text(verbatim: \($0.expression))" } ?? ""
                code.line("ContentUnavailableView(\"Search\", systemImage: \"magnifyingglass\"\(description))")
                if let loading = spec.loadingExpression {
                    code.middle("} else if \(loading) {")
                    code.line("ProgressView()")
                }
                code.middle("} else {")
                code.line("ContentUnavailableView.search(text: \(query))")
                code.close()
            }

        }
        emitter.errorBanner(&code)
    }

    /// A call of the search action: the query as its argument when it takes one.
    private func searchCall(_ action: Action, query: String) -> String {
        if let first = action.params.first { return "\(SwiftName.member(action.name))(\(SwiftName.member(first.name)): \(query))" }
        return "\(SwiftName.member(action.name))()"
    }

    // MARK: - Tabs

    private func tabs(_ code: inout Code) {
        let tabs = spec.labelled
        code.open("var view: some View {")
        code.open("VStack(spacing: 0) {")
        code.open("Picker(\"Section\", selection: center.$state.binding.tab) {")
        for (index, tab) in tabs.enumerated() {
            if case .label(_, let text) = tab.key { code.line("Text(\"\(SwiftName.escaped(text))\").tag(\(index))") }
        }
        code.close()
        code.line(".pickerStyle(.segmented)")
        code.line(".labelsHidden()")
        code.line(".padding()")
        code.open("Group {")
        code.switchOn("state.tab") { code in
            for (index, tab) in tabs.enumerated() {
                code.line(index == tabs.count - 1 ? "default:" : "case \(index):")
                code.line("    \(tab.expression)")
            }
        }
        code.close()
        code.line(".frame(maxWidth: .infinity, maxHeight: .infinity)")
        code.close()
        emitter.finish(&code, items: nil, refreshable: false)
        code.close()
        emitter.errorBanner(&code)
        emitter.readiness(&code)
    }

    // MARK: - A sidebar, a list and a detail

    private func threePane(_ code: inout Code) {
        let items = spec.show("items")?.expression ?? "[]"
        let item = spec.itemName
        let selection = spec.show("selection")?.expression ?? "state.selected"
        let selectionBinding = emitter.binding(selection) ?? "center.$state.binding.selected"
        code.open("var view: some View {")
        if let sidebar = spec.show("sidebar")?.expression {
            let sidebarBinding = spec.show("sidebarSelection").flatMap { emitter.binding($0.expression) }
            let sidebarType = emitter.typeRef(sidebar)?.element?.unwrapped.description
            code.open("NavigationSplitView {")
            code.open(sidebarBinding.map { "List(\(sidebar), selection: \($0)) { entry in" } ?? "List(\(sidebar)) { entry in")
            code.line("\(sidebarRow(type: sidebarType))")
            code.line("    .tag(entry.id)")
            code.close()
            code.line(spec.titleModifier)
            code.line(".navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)")
            code.middle("} content: {")

        } else {
            code.open("NavigationSplitView {")
        }
        code.open("List(\(items), selection: \(selectionBinding)) { \(item) in")
        if let view = spec.rowView { code.block(spec.instance(view, item: item)) } else { code.line("Text(String(describing: \(item)))") }

        code.line("    .tag(\(item).id)")
        code.close()
        code.line(".overlay { status }")
        if let refresh = spec.refresh { code.line(".refreshable { try? await \(SwiftName.member(refresh.name))() }") }
        if spec.show("sidebar") == nil { code.line(spec.titleModifier) }
        code.middle("} detail: {")

        let element = spec.element
        let views = spec.detailViews(for: element)
        code.open("if let \(item) = \(items).first(where: { $0.id == \(selection) }) {")
        code.open("ScrollView {")
        code.open("VStack(alignment: .leading, spacing: 16) {")
        if views.isEmpty { code.line("Text(String(describing: \(item)))") } else { for view in views { code.block(spec.instance(view, item: item)) } }

        code.close()
        code.line(".padding()")
        code.line(".frame(maxWidth: .infinity, alignment: .leading)")
        code.close()
        code.middle("} else {")
        code.line("ContentUnavailableView(\"Nothing Selected\", systemImage: \"sidebar.right\")")

        code.close()
        code.close()
        if spec.errorExpression != nil { code.line(".safeAreaInset(edge: .top, spacing: 0) { errorBanner }") }
        emitter.toolbar(&code)
        if let refresh = spec.refresh, !spec.relays.isEmpty {
            code.scope(".task(id: isReady) {") { code in
                code.line("guard isReady, \(items).isEmpty else { return }")
                code.line("try? await \(SwiftName.member(refresh.name))()")
            }
        }
        code.close()
        helpers(&code, items: items)
    }

    /// A sidebar entry: its title-like field, or the value as text.
    private func sidebarRow(type: String?) -> String {
        if let type, let field = Describe(index: spec.index).title(of: type) { return "Label(\(field.optional ? "entry.\(field.name) ?? \"\"" : "entry.\(field.name)"), systemImage: \"folder\")" }
        return "Text(String(describing: entry))"
    }

    // MARK: - A page of its own

    private func blank(_ code: inout Code) {
        code.open("var view: some View {")
        code.line("content")
        code.indent()
        emitter.finish(&code, items: nil, refreshable: spec.refresh != nil)
        code.dedent()
        code.close()

        code.line()
        code.line("@ViewBuilder")
        code.open("private var content: some View {")
        code.block(spec.bodies["content"] ?? "EmptyView()")
        code.close()
        emitter.errorBanner(&code)
        emitter.readiness(&code)
    }
}
