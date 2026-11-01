//  WHAT: `make: link`: Granite brought into an Xcode project this agent did not make. Granite and GraniteAgents
//        linked into every app target (pinned), the app targets moved to Swift 5 language mode when they are on 6
//        (Granite's reducers hold relays), the root, the boot and settings services and a root page written beside
//        the app's own code, and the root page mounted around the view the App showed.
//  PIN:  IDEMPOTENT. A second call finds the package, the products, the files and the mounted root it made, and adds
//        nothing twice; a file the person already has is kept as it is.
//  PIN:  THE PERSON'S APP IS EDITED ONLY WHERE IT IS PLAIN. A `WindowGroup` that shows one view is wrapped in the
//        root page; anything else is left alone and a note says what to change.

import Foundation

struct LinkMake {
    let input: GraniteAppAgent.Input
    let workspace: Workspace

    func plan() throws -> Plan {
        guard let pbxURL = workspace.pbxprojURL, var project = try workspace.pbxproj() else {
            throw GraniteError.refused(["link brings Granite into an Xcode project, and there is none here: call it in the folder with the .xcodeproj (or `make: project` for a new app)"])
        }
        var problems: [String] = []
        let apps = project.applicationTargets
        if apps.isEmpty { problems.append("\(workspace.project!.lastPathComponent) has no app target to link Granite into") }
        var packages: [PackageDependency] = []
        for line in input.packages ?? [] {
            do { packages.append(try PackageLine.parse(line)) } catch { problems.append("\(error)") }
        }
        let index = ProjectIndex(root: workspace.root)
        let root = (input.root ?? "Home").trimmingCharacters(in: .whitespaces)
        problems += ProjectMake.rootProblems(root, app: workspace.appName ?? "")
        if index.components[root] == nil, index.declared.contains(root) {
            problems.append("the project already has a type named `\(root)`: name the root page with `root`")
        }
        let layout = AppLayout.detect(workspace)
        let source = input.into.map { workspace.files.resolve($0) } ?? layout.source
        guard problems.isEmpty else { throw GraniteError.refused(problems) }

        var plan = Plan()
        // The package, linked into every app target.
        let before = project.text
        let granite = try project.remotePackage(GranitePin.url, requirement: .revision(GranitePin.revision), name: "Granite")
        for target in apps {
            for product in GranitePin.products { try project.link(product, package: granite, into: target.id) }
        }
        for package in packages {
            let reference = try project.remotePackage(package.url, requirement: package.requirement, name: package.identity)
            for target in apps { for product in package.products { try project.link(product, package: reference, into: target.id) } }
        }
        var moved: [String] = []
        for target in project.applicationTargets {
            let version = project.settings(of: target)?["SWIFT_VERSION"]?.string ?? ""
            if version.hasPrefix("6") {
                try project.setBuildSetting("SWIFT_VERSION", to: "5.0", target: target.id)
                moved.append(target.name)
            }
        }
        if project.text != before {
            plan.write(pbxURL, project.text, role: .other)
            plan.notes.append("linked Granite and GraniteAgents (pinned at \(GranitePin.revision.prefix(8))) into \(apps.map(\.name).joined(separator: " and "))")
        }
        if !moved.isEmpty {
            plan.notes.append("\(moved.joined(separator: " and ")) build in Swift 5 language mode now: Granite's reducers hold relays, which Swift 6 refuses")
        }

        // The root, the boot and settings services, and the root page, beside the app's own code.
        var kept: [String] = []
        func add(_ url: URL, _ text: String, role: Plan.Role = .app) {
            if FileManager.default.fileExists(atPath: url.path) { kept.append(workspace.files.relative(url)); return }
            plan.write(url, text, role: role)
        }
        let utility = layout.isLoom ? layout.utility : source.appendingPathComponent("Utility")
        let services = layout.isLoom ? layout.services : source.appendingPathComponent("Services")
        let components = layout.isLoom ? layout.components : source.appendingPathComponent("Components")
        if index.appRoot == nil { add(utility.appendingPathComponent("AppRoot.swift"), AppTemplates.root) }
        if !index.swiftFiles.contains(where: { (try? String(contentsOf: $0, encoding: .utf8))?.contains("func modalHosted()") == true }) {
            add(utility.appendingPathComponent("ModalHosting.swift"), AppTemplates.modalHostingInert)
        }
        for (path, text) in BootTemplates.files(app: workspace.appName ?? "app") where index.services[String(path.split(separator: "/")[0])] == nil {
            add(services.appendingPathComponent(path), text)
        }
        if index.components[root] == nil {
            add(components.appendingPathComponent("\(root)/\(root).swift"), RootTemplates.component(root, hostsContent: true))
            add(components.appendingPathComponent("\(root)/\(root)+Center.swift"), RootTemplates.center(root))
            add(components.appendingPathComponent("\(root)/\(root)+View.swift"), RootTemplates.view(root, ready: .content))
        }
        if let (folder, module) = try workspace.unitTests(), !FileManager.default.fileExists(atPath: folder.appendingPathComponent("BootTests.swift").path) {
            plan.write(folder.appendingPathComponent("BootTests.swift"), BootTemplates.tests(name: "Boot", module: module), role: .tests)
        }
        if !kept.isEmpty { plan.notes.append("kept what the project already had: \(kept.joined(separator: ", "))") }

        // The root page, mounted around the view the App showed.
        if let app = layout.app, let text = plan.text(at: app) ?? (try? String(contentsOf: app, encoding: .utf8)) {
            if text.range(of: #"\b\#(root)\s*(\{|\()"#, options: .regularExpression) != nil {
                // Mounted already.
            } else if let mounted = Self.mount(root, in: text) {
                plan.write(app, mounted)
                plan.notes.append("\(workspace.files.relative(app)) shows \(root) around the view it showed, which appears once the app has booted")
            } else {
                plan.notes.append("\(workspace.files.relative(app))'s WindowGroup shows more than one view, so it was left alone: wrap what it shows in `\(root) { … }` so the app boots before it appears")
            }
        } else {
            plan.notes.append("no @main App was found: show `\(root) { YourView() }` in the app's WindowGroup so the app boots")
        }
        plan.types = ["AppRoot", "EnvironmentService", "ConfigService", root].filter { type in plan.files.contains { $0.url.lastPathComponent.hasPrefix(type) } }
        if plan.files.isEmpty { plan.notes.append("Granite was linked and everything is in place: nothing to add") }
        return plan
    }

    /// `text` with the one view its `WindowGroup` shows wrapped in `root`; nil when the group shows anything else.
    static func mount(_ root: String, in text: String) -> String? {
        let pattern = #"(?m)^([ \t]*)WindowGroup\s*\{\s*\n([ \t]*)([A-Z][A-Za-z0-9_]*)\(\)\s*\n[ \t]*\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text)) == 1,
              let whole = Range(match.range, in: text), let outer = Range(match.range(at: 1), in: text),
              let inner = Range(match.range(at: 2), in: text), let view = Range(match.range(at: 3), in: text) else { return nil }
        let o = String(text[outer]), i = String(text[inner]), name = String(text[view])
        let replacement = "\(o)WindowGroup {\n\(i)\(root) {\n\(i)    \(name)()\n\(i)}\n\(o)}"
        return text.replacingCharacters(in: whole, with: replacement)
    }
}
