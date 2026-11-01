//  WHAT: The app's navigation: its destinations, the platform navigation views (a tab bar on a compact iPhone, a
//        sidebar beside the page on iPad and the Mac, three columns in the split style), the layout service that
//        holds where the app is (persisted destination, compact or expanded, the detail pane's selection, the Mac
//        window widened in a main-actor hop), routes over Granite's router, and what the app runs on.
//  PIN:  THE DESTINATION LIVES IN A SERVICE. A menu, a key or another page moves the app (`layout.select(.feed)`),
//        so the selection is LayoutService's, not the navigation view's (skill §3).

import Foundation

enum NavigationTemplates {
    // MARK: - Destinations

    static func destinations(_ destinations: [Destination], split: Bool) -> String {
        var code = Code()
        code.line("import SwiftUI")
        code.line()
        code.line("/// The places the app goes: what its tab bar and its sidebar list, each with its title, its symbol and its page.")
        code.open("enum AppDestination: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {")
        for destination in destinations { code.line("case \(SwiftName.member(destination.name))") }
        code.line()
        code.line("var id: Self { self }")
        code.line()
        code.line("/// The destination's name, as the tab bar and the sidebar show it.")
        code.scope("var title: String {") { code in
            code.switchOn("self") { code in
                for destination in destinations {
                    code.line("case .\(SwiftName.member(destination.name)): String(localized: \"\(SwiftName.escaped(destination.title))\")")
                }
            }
        }
        code.line()
        code.line("/// The SF Symbol beside its name.")
        code.scope("var symbol: String {") { code in
            code.switchOn("self") { code in
                for destination in destinations { code.line("case .\(SwiftName.member(destination.name)): \"\(destination.symbol)\"") }
            }
        }
        code.line()
        code.line("/// The page it shows.")
        code.line("@MainActor @ViewBuilder")
        code.scope("var view: some View {") { code in
            code.switchOn("self") { code in
                for destination in destinations { code.line("case .\(SwiftName.member(destination.name)): \(destination.view)") }
            }
        }
        if split {
            code.line()
            code.line("/// What the detail pane shows beside the page, in the split style.")
            code.line("@MainActor @ViewBuilder")
            code.scope("var detail: some View {") { code in
                code.switchOn("self") { code in
                    let detailed = destinations.filter { $0.detail != nil }
                    for destination in detailed { code.line("case .\(SwiftName.member(destination.name)): \(destination.detail!)") }
                    if detailed.count < destinations.count {
                        code.line("default: ContentUnavailableView(\"Nothing Selected\", systemImage: \"sidebar.right\")")
                    }
                }
            }
        }
        code.close()
        return code.text
    }

    // MARK: - The navigation views

    static func iOS(style: GraniteStyle, appTitle: String) -> String {
        var code = Code()
        code.line("#if os(iOS)")
        code.line("import Granite")
        code.line("import SwiftUI")
        code.line()
        switch style {
        case .adaptive: code.line("/// The app's navigation on iPhone and iPad: a tab bar on a compact width, a sidebar beside the page on a regular one.")
        case .tabs: code.line("/// The app's navigation on iPhone and iPad: a tab bar of its destinations.")
        case .sidebar: code.line("/// The app's navigation on iPhone and iPad: a sidebar of its destinations beside the page; on iPhone it collapses into a list.")
        case .split: code.line("/// The app's navigation on iPhone and iPad: its destinations, the page and its detail, side by side.")
        }
        code.open("struct PlatformNavigationView: View {")
        code.line("@Relay var layout: LayoutService")
        code.line("@StateObject private var clock = RelayClock([RelayClock.on(LayoutService.self)])")
        code.line("@Environment(\\.horizontalSizeClass) private var horizontalSizeClass")
        code.line()
        code.open("var body: some View {")
        switch style {
        case .adaptive:
            code.open("Group {")
            code.open("if horizontalSizeClass == .compact {")
            code.line("tabs")
            code.middle("} else {")
            code.line("sidebar")
            code.close()
            code.close()
        case .tabs: code.line("tabs")
        case .sidebar: code.line("sidebar")
        case .split: code.line("columns")
        }
        code.scope(".onChange(of: horizontalSizeClass, initial: true) { _, sizeClass in") { code in
            code.line("layout.set(.style(sizeClass == .compact ? .compact : .expanded))")
        }
        code.close()
        if style == .adaptive || style == .tabs {
            code.line()
            code.scope("private var tabs: some View {") { code in
                code.scope("TabView(selection: layout.binding(\\.destination) { .destination($0) }) {") { code in
                    code.scope("ForEach(AppDestination.allCases) { destination in") { code in
                        code.scope("NavigationStack {") { $0.line("destination.view") }
                        code.line(".tabItem { Label(destination.title, systemImage: destination.symbol) }")
                        code.line(".tag(destination)")
                    }
                }
            }
        }
        if style == .adaptive || style == .sidebar {
            code.line()
            code.scope("private var sidebar: some View {") { code in
                code.open("NavigationSplitView {")
                sidebarList(&code, title: appTitle)
                code.middle("} detail: {")
                code.scope("NavigationStack {") { $0.line("layout.state.destination.view") }
                code.close()
            }
        }
        if style == .split {
            code.line()
            code.scope("private var columns: some View {") { code in
                code.open("NavigationSplitView {")
                sidebarList(&code, title: appTitle)
                code.middle("} content: {")
                code.scope("NavigationStack {") { $0.line("layout.state.destination.view") }
                code.middle("} detail: {")
                code.line("layout.state.destination.detail")
                code.close()
            }
        }
        selection(&code)
        code.close()
        code.line("#endif")
        return code.text
    }

    static func macOS(style: GraniteStyle, appTitle: String) -> String {
        var code = Code()
        code.line("#if os(macOS)")
        code.line("import Granite")
        code.line("import SwiftUI")
        code.line()
        code.line(style == .split
                  ? "/// The app's navigation on the Mac: its destinations, the page and its detail side by side; the window widens when the detail opens."
                  : "/// The app's navigation on the Mac: a sidebar of its destinations beside the page.")
        code.open("struct PlatformNavigationView: View {")
        code.line("@Relay var layout: LayoutService")
        code.line("@StateObject private var clock = RelayClock([RelayClock.on(LayoutService.self)])")
        code.line()
        code.open("var body: some View {")
        code.open("NavigationSplitView {")
        sidebarList(&code, title: appTitle)
        if style == .split {
            code.middle("} content: {")
            code.scope("NavigationStack {") { $0.line("layout.state.destination.view") }
            code.middle("} detail: {")
            code.line("layout.state.destination.detail")
        } else {
            code.middle("} detail: {")
            code.scope("NavigationStack {") { $0.line("layout.state.destination.view") }
        }
        code.close()
        code.line(".frame(minWidth: LayoutService.minimumWidth, minHeight: LayoutService.minimumHeight)")
        code.line(".onAppear { layout.set(.style(.expanded)) }")
        if style == .split {
            code.scope(".onChange(of: layout.state.detail) { _, detail in") { code in
                code.line("LayoutService.resizeWindow(width: detail == nil ? LayoutService.compactWidth : LayoutService.expandedWidth)")
            }
        }
        code.close()
        selection(&code)
        code.close()
        code.line("#endif")
        return code.text
    }

    private static func sidebarList(_ code: inout Code, title: String) {
        code.scope("List(AppDestination.allCases, selection: sidebarSelection) { destination in") { code in
            code.line("Label(destination.title, systemImage: destination.symbol)")
            code.line("    .tag(destination)")
        }
        code.line(".navigationTitle(\"\(SwiftName.escaped(title))\")")
        code.line(".navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)")
    }

    private static func selection(_ code: inout Code) {
        code.line()
        code.line("/// The sidebar's selection: one destination is always chosen.")
        code.scope("private var sidebarSelection: Binding<AppDestination?> {") { code in
            code.scope("Binding(get: { layout.state.destination }, set: { destination in", close: "})") { code in
                code.line("if let destination { layout.set(.destination(destination)) }")
            }
        }

    }
}
