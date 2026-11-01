//  WHAT: Packages in an Xcode project: a remote reference pinned to a revision or a version, a local reference to a
//        folder of the project, and a product of either linked into a target (a product dependency and a build file
//        in its Frameworks phase).
//  PIN:  IDEMPOTENT. A reference is found by its URL (with or without `.git`) or its folder, a product by its name on
//        the target; a second call finds what the first made and adds nothing twice.

import Foundation

extension Pbxproj {
    /// The project's reference to the remote package at `url`, made (pinned by `requirement`) when it has none.
    mutating func remotePackage(_ url: String, requirement: PackageDependency.Requirement, name: String) throws -> String {
        let wanted = Self.normalized(url)
        if let existing = objects("XCRemoteSwiftPackageReference").first(where: { Self.normalized($0.string("repositoryURL") ?? "") == wanted }) {
            return existing.id
        }
        let id = freshID()
        let pin: String
        switch requirement {
        case .revision(let revision): pin = "\t\t\t\tkind = revision;\n\t\t\t\trevision = \(revision);\n"
        case .exact(let version): pin = "\t\t\t\tkind = exactVersion;\n\t\t\t\tversion = \(version);\n"
        }
        let comment = "XCRemoteSwiftPackageReference \"\(name)\""
        try insert("\t\t\(id) /* \(comment) */ = {\n\t\t\tisa = XCRemoteSwiftPackageReference;\n\t\t\trepositoryURL = \"\(url)\";\n\t\t\trequirement = {\n\(pin)\t\t\t};\n\t\t};\n",
                   isa: "XCRemoteSwiftPackageReference")
        try append("\(id) /* \(comment) */", to: "packageReferences", of: rootObject)
        return id
    }

    /// The project's reference to the package in its folder `relativePath`, made when it has none.
    mutating func localPackage(_ relativePath: String, name: String) throws -> String {
        if let existing = objects("XCLocalSwiftPackageReference").first(where: { $0.string("relativePath") == relativePath }) {
            return existing.id
        }
        let id = freshID()
        let comment = "XCLocalSwiftPackageReference \"\(name)\""
        try insert("\t\t\(id) /* \(comment) */ = {\n\t\t\tisa = XCLocalSwiftPackageReference;\n\t\t\trelativePath = \(Self.quoted(relativePath));\n\t\t};\n",
                   isa: "XCLocalSwiftPackageReference")
        try append("\(id) /* \(comment) */", to: "packageReferences", of: rootObject)
        return id
    }

    /// Links `product` of the package `reference` into the target `targetID`. False when it was linked already.
    @discardableResult
    mutating func link(_ product: String, package reference: String, into targetID: String) throws -> Bool {
        guard let target = targets.first(where: { $0.id == targetID }) else { throw GraniteError.refused(["the project has no target \(targetID)"]) }
        let linked = target.object.list("packageProductDependencies").compactMap { objects[$0] }
        if linked.contains(where: { $0.string("productName") == product }) { return false }
        let referenceComment = comment(for: reference)
        let dependency = freshID()
        try insert("\t\t\(dependency) /* \(product) */ = {\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tpackage = \(reference) /* \(referenceComment) */;\n\t\t\tproductName = \(product);\n\t\t};\n",
                   isa: "XCSwiftPackageProductDependency")
        try append("\(dependency) /* \(product) */", to: "packageProductDependencies", of: targetID)
        let buildFile = freshID()
        try insert("\t\t\(buildFile) /* \(product) in Frameworks */ = {isa = PBXBuildFile; productRef = \(dependency) /* \(product) */; };\n", isa: "PBXBuildFile")
        let frameworks = try phaseID("PBXFrameworksBuildPhase", name: "Frameworks", of: targetID)
        try append("\(buildFile) /* \(product) in Frameworks */", to: "files", of: frameworks)
        return true
    }

    /// The target's build phase of a kind, made (after its Sources phase) when it has none.
    mutating func phaseID(_ isa: String, name: String, of targetID: String) throws -> String {
        guard let target = targets.first(where: { $0.id == targetID }) else { throw GraniteError.refused(["the project has no target \(targetID)"]) }
        if let phase = phase(isa, of: target) { return phase.id }
        let id = freshID()
        try insert("\t\t\(id) /* \(name) */ = {\n\t\t\tisa = \(isa);\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n", isa: isa)
        try append("\(id) /* \(name) */", to: "buildPhases", of: targetID)
        return id
    }

    /// Sets `key` in every configuration of the target `targetID`.
    mutating func setBuildSetting(_ key: String, to value: String, target targetID: String) throws {
        guard let target = targets.first(where: { $0.id == targetID }),
              let list = target.object.string("buildConfigurationList").flatMap({ objects[$0] }) else { return }
        for configuration in list.list("buildConfigurations") {
            try setBuildSetting(key, to: value, in: configuration)
        }
    }

    /// The comment Xcode writes beside a package reference's id.
    func comment(for reference: String) -> String {
        guard let object = objects[reference] else { return "" }
        if object.isa == "XCLocalSwiftPackageReference" {
            return "XCLocalSwiftPackageReference \"\((object.string("relativePath") ?? "").split(separator: "/").last.map(String.init) ?? "")\""
        }
        let url = object.string("repositoryURL") ?? ""
        let last = url.split(separator: "/").last.map(String.init) ?? url
        return "XCRemoteSwiftPackageReference \"\(last.hasSuffix(".git") ? String(last.dropLast(4)) : last)\""
    }

    /// A URL as a package's identity: no scheme's case, no `.git`, no trailing slash.
    static func normalized(_ url: String) -> String {
        var text = url.lowercased().trimmingCharacters(in: .whitespaces)
        if text.hasSuffix("/") { text.removeLast() }
        if text.hasSuffix(".git") { text.removeLast(4) }
        return text
    }

    /// A value as the project file writes it: bare when it can be, quoted when it holds anything else.
    static func quoted(_ value: String) -> String {
        if !value.isEmpty, value.allSatisfy({ $0.isLetter || $0.isNumber || "_./$".contains($0) }), value.unicodeScalars.allSatisfy(\.isASCII) {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
