//  WHAT: `make: navigation`: the app's destinations and how it moves between them (adaptive, tabs, sidebar or
//        split), the layout service, routes and Device, and the root page shown with them once the app is ready.
//  PIN:  THE PAGES COME FIRST. A destination names a page the project has; one it does not is refused, never
//        written as a placeholder.

import Foundation

struct NavigationMake {
    let input: GraniteAppAgent.Input
    let workspace: Workspace

    func plan() throws -> Plan {
        guard workspace.project != nil else {
            throw GraniteError.refused(["navigation is an app's: call it in the folder with the app's .xcodeproj"])
        }
        var problems: [String] = []
        let index = ProjectIndex(root: workspace.root)
        let layout = AppLayout.detect(workspace)
        var destinations: [Destination] = []
        for line in input.destinations ?? [] where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            do {
                let destination = try DestinationLine.parse(line)
                if destinations.contains(where: { $0.name == destination.name }) {
                    problems.append("the destination `\(destination.name)` is named twice")
                    continue
                }
                for type in [destination.viewType, destination.detailType].compactMap({ $0 }) where !index.declared.contains(type) {
                    problems.append("`\(type)` is not in the project: make the page first (`make: component`, `type: \(type)`)")
                }
                destinations.append(destination)
            } catch { problems.append("\(error)") }
        }
        if destinations.isEmpty { problems.append("name the app's destinations, one a line: `feed: Feed \"Feed\" house`") }
        let style = input.style ?? .adaptive
        let root = input.root?.trimmingCharacters(in: .whitespaces) ?? Self.rootPage(layout) ?? "Home"
        let rootView = index.components[root]?.deletingLastPathComponent().appendingPathComponent("\(root)+View.swift")
        if let rootView {
            let text = (try? String(contentsOf: rootView, encoding: .utf8)) ?? ""
            if !text.contains("AppRoot.shared.boot()") {
                problems.append("\(workspace.files.relative(rootView)) is not the root page this agent writes (it does not boot the app), so it is not replaced: name the root with `root`")
            }
        } else {
            problems.append("the root page `\(root)` is not in the project: name it with `root`")
        }
        guard problems.isEmpty, let rootView else { throw GraniteError.refused(problems) }

        var plan = Plan()
        let title = workspace.appName ?? root
        plan.write(layout.utility.appendingPathComponent("AppDestination.swift"), NavigationTemplates.destinations(destinations, split: style == .split))
        if layout.isLoom {
            plan.write(layout.ios.appendingPathComponent("PlatformNavigationView.swift"), NavigationTemplates.iOS(style: style, appTitle: title))
            plan.write(layout.macos.appendingPathComponent("PlatformNavigationView.swift"), NavigationTemplates.macOS(style: style, appTitle: title))
        } else {
            // One target builds both platforms here: two files of one name would collide, so both views share a file.
            plan.write(layout.utility.appendingPathComponent("PlatformNavigationView.swift"),
                       NavigationTemplates.iOS(style: style, appTitle: title) + "\n" + NavigationTemplates.macOS(style: style, appTitle: title))
        }

        plan.write(layout.utility.appendingPathComponent("Routes.swift"), NavigationTemplates.routes)
        if index.types["Device"] == nil || index.types["Device"].map({ _ in FileManager.default.fileExists(atPath: layout.utility.appendingPathComponent("Device.swift").path) }) == true {
            plan.write(layout.utility.appendingPathComponent("Device.swift"), NavigationTemplates.device)
        } else {
            plan.notes.append("the project has a Device of its own, so it is kept")
        }
        let first = SwiftName.member(destinations[0].name)
        for (path, text) in NavigationTemplates.layoutService(app: workspace.appName ?? "app", first: first) {
            plan.write(layout.services.appendingPathComponent("LayoutService/\(path)"), text)
        }
        plan.write(rootView, RootTemplates.view(root, ready: .navigation))
        if let (folder, module) = try workspace.unitTests() {
            plan.write(folder.appendingPathComponent("LayoutOpsTests.swift"),
                       NavigationTemplates.layoutTests(module: module, first: first, second: SwiftName.member(destinations[destinations.count > 1 ? 1 : 0].name)),
                       role: .tests)
        }
        if !index.hasRelayClock { plan.write(layout.utility.appendingPathComponent("RelayClock.swift"), UtilityTemplates.relayClock) }
        if let (file, text) = workspace.rootAdding("LayoutService", index: index, plan: plan) { plan.write(file, text) }

        plan.types = ["AppDestination", "PlatformNavigationView", "LayoutService", "Routes", "Device", root]
        switch style {
        case .adaptive: plan.notes.append("a tab bar on a compact iPhone, a sidebar beside the page on iPad and the Mac")
        case .tabs: plan.notes.append("a tab bar on iPhone and iPad, a sidebar on the Mac")
        case .sidebar: plan.notes.append("a sidebar beside the page everywhere; on iPhone it collapses into a list")
        case .split: plan.notes.append("the destinations, the page and its detail side by side; a page opens the detail with `layout.show(detail: id)`, and the Mac window widens for it")
        }
        if style != .split, destinations.contains(where: { $0.detail != nil }) {
            plan.notes.append("a destination's `| Detail` is shown only in the split style, so it was left out")
        }
        plan.notes.append("the selected destination persists in LayoutService; a menu or a page moves the app with `layout.select(.\(first))`")
        return plan
    }

    /// The page the App's window opens with: the first call in its `WindowGroup`.
    static func rootPage(_ layout: AppLayout) -> String? {
        guard let app = layout.app, let text = try? String(contentsOf: app, encoding: .utf8),
              let group = text.range(of: "WindowGroup") else { return nil }
        let after = String(text[group.upperBound...])
        return after.matches(
#"\{\s*([A-Z][A-Za-z0-9_]*)\s*[\(\{]"#).first
    }
}
