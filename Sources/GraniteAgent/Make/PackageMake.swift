//  WHAT: `make: package`: a kit of services. In an app, it goes in `Packages/<Name>` (the Loom layout) and is linked
//        into every app target; elsewhere it is a package of its own. `make: service` with `into` the kit's folder
//        then writes public services into it, and the kit's root holds them.

import Foundation

struct PackageMake {
    let input: GraniteAppAgent.Input
    let workspace: Workspace

    func plan() throws -> Plan {
        var problems: [String] = []
        let name = (input.name ?? "").trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            problems.append("name the kit with `name`, like `RecipeKit`")
        } else if name.range(of: #"^[A-Za-z][A-Za-z0-9]*$"#, options: .regularExpression) == nil {
            problems.append("the kit's name `\(name)` must start with a letter and hold only letters and digits")
        }
        var packages: [PackageDependency] = []
        for line in input.packages ?? [] {
            do { packages.append(try PackageLine.parse(line)) } catch { problems.append("\(error)") }
        }
        let folder: URL
        if let into = input.into, !into.trimmingCharacters(in: .whitespaces).isEmpty {
            folder = workspace.files.resolve(into)
        } else if workspace.project != nil {
            folder = workspace.root.appendingPathComponent("Packages/\(name)")
        } else {
            let contents = ((try? FileManager.default.contentsOfDirectory(atPath: workspace.files.root.path)) ?? []).filter { !$0.hasPrefix(".") }
            folder = contents.isEmpty ? workspace.files.root : workspace.files.root.appendingPathComponent(name)
        }
        if FileManager.default.fileExists(atPath: folder.appendingPathComponent("Package.swift").path) {
            problems.append("\(workspace.files.relative(folder)) already holds a Package.swift: a package is never written over")
        }
        guard problems.isEmpty else { throw GraniteError.refused(problems) }

        var plan = Plan()
        plan.write(folder.appendingPathComponent("Package.swift"), PackageTemplates.manifest(name: name, packages: packages), role: .other)
        plan.write(folder.appendingPathComponent("Sources/\(name)/\(name)Root.swift"), PackageTemplates.root(name: name), role: .other)
        plan.write(folder.appendingPathComponent("Tests/\(name)Tests/\(name)Tests.swift"), PackageTemplates.tests(name: name), role: .other)
        plan.write(folder.appendingPathComponent(".gitignore"), PackageTemplates.gitignore, role: .other)
        plan.types = ["\(name)Root"]

        if let url = workspace.pbxprojURL, var project = try workspace.pbxproj(), let relative = workspace.relativeToRoot(folder) {
            let reference = try project.localPackage(relative, name: name)
            for target in project.applicationTargets { try project.link(name, package: reference, into: target.id) }
            plan.write(url, project.text, role: .other)
            plan.notes.append("linked \(name) into \(project.applicationTargets.map(\.name).joined(separator: " and "))")
        }
        plan.notes.append("put a public service in it with `make: service` and `into: \"\(workspace.files.relative(folder))\"`; \(name)Root holds each one")
        return plan
    }
}
