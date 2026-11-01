//  WHAT: `make: project`: a new iOS + macOS app in the Loom layout. Its Xcode project (synchronized folders, an app,
//        unit tests and UI tests per platform, two shared schemes, Granite pinned and linked), the App and its
//        delegate, the menu commands, the root that holds the relays, the boot and settings services, the root
//        page, the modal host it applies, the asset catalog, and the tests of the two services.
//  PIN:  NEVER OVER A PROJECT. A folder that already holds an Xcode project or an app is refused: `link` brings
//        Granite into a project this package did not make.

import Foundation

struct ProjectMake {
    let input: GraniteAppAgent.Input
    let files: AgentFiles

    func plan() throws -> Plan {
        var problems: [String] = []
        let name = (input.name ?? "").trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            problems.append("name the app with `name`: letters and digits, like `Recipes`")
        } else if name.range(of: #"^[A-Za-z][A-Za-z0-9]*$"#, options: .regularExpression) == nil {
            problems.append("the app's name `\(name)` must start with a letter and hold only letters and digits")
        }
        let bundleId = (input.bundleId ?? "com.example.\(name.lowercased())").trimmingCharacters(in: .whitespaces)
        if bundleId.range(of: #"^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$"#, options: .regularExpression) == nil {
            problems.append("`\(bundleId)` is not a bundle identifier (reverse DNS, like `com.example.recipes`)")
        }
        let team = (input.team ?? "").trimmingCharacters(in: .whitespaces)
        if !team.isEmpty, team.range(of: #"^[A-Z0-9]{10}$"#, options: .regularExpression) == nil {
            problems.append("`\(team)` is not a team: a team is the 10-character id Apple gave it")
        }
        let root = (input.root ?? "Home").trimmingCharacters(in: .whitespaces)
        problems += Self.rootProblems(root, app: name)
        var packages: [PackageDependency] = []
        for line in input.packages ?? [] {
            do { packages.append(try PackageLine.parse(line)) } catch { problems.append("\(error)") }
        }
        let folder = files.resolve(input.into ?? ".")
        if let existing = Workspace.contents(of: folder).first(where: { $0.pathExtension == "xcodeproj" }) {
            problems.append("\(files.relative(folder).isEmpty ? "the folder" : files.relative(folder)) already holds \(existing.lastPathComponent): a project is never written over (use `make: link` to bring Granite into it)")
        } else if FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared/App.swift").path) {
            problems.append("\(files.relative(folder.appendingPathComponent("Shared/App.swift"))) already exists: a project is never written over")
        }
        guard problems.isEmpty else { throw GraniteError.refused(problems) }

        var plan = Plan()
        let (projectText, ids) = try Self.projectFile(name: name, bundleId: bundleId, team: team, packages: packages)
        let project = folder.appendingPathComponent("\(name).xcodeproj")
        plan.write(project.appendingPathComponent("project.pbxproj"), projectText, role: .other)
        plan.write(project.appendingPathComponent("project.xcworkspace/contents.xcworkspacedata"), XcodeTemplates.workspace, role: .other)
        for (platform, suffix) in [("iOS", "IOS"), ("macOS", "MAC")] {
            plan.write(project.appendingPathComponent("xcshareddata/xcschemes/\(name)-\(platform).xcscheme"),
                       XcodeTemplates.scheme(name: name, platform: platform, app: ids["APP_\(suffix)"]!, tests: ids["TESTS_\(suffix)"]!, uiTests: ids["UITESTS_\(suffix)"]!),
                       role: .other)
        }
        plan.write(folder.appendingPathComponent("Shared/App.swift"), AppTemplates.app(name: name, root: root))
        plan.write(folder.appendingPathComponent("Shared/AppDelegate.swift"), AppTemplates.delegate)
        plan.write(folder.appendingPathComponent("Shared/Assets.xcassets/Contents.json"), AppTemplates.assetsContents, role: .other)
        plan.write(folder.appendingPathComponent("Shared/Assets.xcassets/AccentColor.colorset/Contents.json"), AppTemplates.accentColor, role: .other)
        plan.write(folder.appendingPathComponent("Shared/Assets.xcassets/AppIcon.appiconset/Contents.json"), AppTemplates.appIcon, role: .other)
        plan.write(folder.appendingPathComponent("Shared/Utility/AppRoot.swift"), AppTemplates.root)
        plan.write(folder.appendingPathComponent("Shared/Utility/ModalHosting.swift"), AppTemplates.modalHostingInert)
        plan.write(folder.appendingPathComponent("macOS/AppCommands.swift"), AppTemplates.commands)
        let components = folder.appendingPathComponent("Components/\(root)")
        plan.write(components.appendingPathComponent("\(root).swift"), RootTemplates.component(root, hostsContent: false))
        plan.write(components.appendingPathComponent("\(root)+Center.swift"), RootTemplates.center(root))
        plan.write(components.appendingPathComponent("\(root)+View.swift"), RootTemplates.view(root, ready: .welcome(name)))
        for (path, text) in BootTemplates.files(app: name) {
            plan.write(folder.appendingPathComponent("Services/\(path)"), text)
        }
        plan.write(folder.appendingPathComponent("Tests/\(name)Tests.swift"), BootTemplates.tests(name: name, module: name), role: .tests)
        plan.write(folder.appendingPathComponent("UITests/\(name)UITests.swift"), AppTemplates.uiTests(name: name), role: .other)
        plan.write(folder.appendingPathComponent(".gitignore"), AppTemplates.gitignore, role: .other)

        plan.types = [AppTemplates.appType(name), root, "AppRoot", "EnvironmentService", "ConfigService"]
        plan.notes.append("\(name)-iOS and \(name)-macOS build the app and run its tests; Granite is pinned at \(GranitePin.revision.prefix(8)) and linked with GraniteAgents")
        plan.notes.append("a file written under Shared, Components, Services, iOS, macOS, Tests or UITests joins its targets with no project edit")
        if !packages.isEmpty { plan.notes.append("linked \(packages.flatMap(\.products).joined(separator: ", ")) into both apps") }
        plan.notes.append("next: the app's services (`make: service`), its pages (`make: component`), then `make: navigation` and `make: modals`")
        return plan
    }

    /// Why `root` cannot name the root page, if it cannot.
    static func rootProblems(_ root: String, app: String) -> [String] {
        guard SwiftName.isTypeName(root) else { return ["the root page `\(root)` must be a type name in UpperCamelCase, like `Home`"] }
        let taken: Set<String> = ["App", "AppRoot", "AppDelegate", "AppCommands", "Center", "State", "View", "Settings", "Group", "List", "Text", AppTemplates.appType(app), app]
        return taken.contains(root) ? ["the root page cannot be named `\(root)`: the app or SwiftUI already has a type by that name"] : []
    }

    /// The project file, its objects given fresh ids, with Granite and `packages` linked into both apps.
    static func projectFile(name: String, bundleId: String, team: String, packages: [PackageDependency]) throws -> (String, [String: String]) {
        var used: Set<String> = []
        var ids: [String: String] = [:]
        for token in XcodeTemplates.tokens {
            var id: String
            repeat {
                id = String(format: "%016llX", UInt64.random(in: 0...UInt64.max)) + String(format: "%08X", UInt32.random(in: 0...UInt32.max))
            } while used.contains(id)
            used.insert(id)
            ids[token] = id
        }
        var project = try Pbxproj(XcodeTemplates.project(name: name, bundleId: bundleId, team: team) { ids[$0] ?? $0 })
        let granite = try project.remotePackage(GranitePin.url, requirement: .revision(GranitePin.revision), name: "Granite")
        for target in [ids["APP_IOS"]!, ids["APP_MAC"]!] {
            for product in GranitePin.products { try project.link(product, package: granite, into: target) }
        }
        for package in packages {
            let reference = try project.remotePackage(package.url, requirement: package.requirement, name: package.identity)
            for target in [ids["APP_IOS"]!, ids["APP_MAC"]!] {
                for product in package.products { try project.link(product, package: reference, into: target) }
            }
        }
        if let failure = Pbxproj.lint(project.text) { throw GraniteError.refused(["the project file made does not read: \(failure)"]) }
        return (project.text, ids)
    }
}
