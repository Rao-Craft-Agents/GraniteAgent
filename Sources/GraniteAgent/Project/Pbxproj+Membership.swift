//  WHAT: A file joining targets of an Xcode project. Under a folder a target synchronizes, it already has; in a
//        project of classic groups it gets a file reference in the group of its folder (the groups made as needed)
//        and a build file in each target's Sources phase.
//  PIN:  A SYNCHRONIZED FOLDER IS WHERE THE PROJECT PUT IT. A file under a folder any target synchronizes joins the
//        targets that folder joins (`iOS/` the iOS app, `Tests/` the tests) and no other: adding it elsewhere would
//        compile one platform's file into the other's app.
//  PIN:  IDEMPOTENT. A reference already in its group, or a build file already in a phase, is found and kept.


import Foundation

extension Pbxproj {
    /// Puts the Swift file at `path` (relative to the project's folder) into the targets `targetIDs`. True when the
    /// project file changed.
    @discardableResult
    mutating func include(_ path: String, in targetIDs: [String]) throws -> Bool {
        let synchronized = targets.flatMap { synchronizedFolders(of: $0) }
        if synchronized.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) { return false }
        let uncovered = targetIDs.filter { id in targets.contains { $0.id == id } }
        guard !uncovered.isEmpty else { return false }

        let components = path.split(separator: "/").map(String.init)
        guard let fileName = components.last else { return false }
        let before = text
        let group = try group(for: Array(components.dropLast()))
        let reference: String
        if let existing = objects[group]?.list("children").compactMap({ objects[$0] })
            .first(where: { $0.isa == "PBXFileReference" && ($0.string("path") == fileName || $0.string("name") == fileName) }) {
            reference = existing.id
        } else {
            reference = freshID()
            let type = fileName.hasSuffix(".swift") ? "sourcecode.swift" : "text"
            try insert("\t\t\(reference) /* \(fileName) */ = {isa = PBXFileReference; lastKnownFileType = \(type); path = \(Self.quoted(fileName)); sourceTree = \"<group>\"; };\n",
                       isa: "PBXFileReference")
            try append("\(reference) /* \(fileName) */", to: "children", of: group)
        }
        for targetID in uncovered {
            let sources = try phaseID("PBXSourcesBuildPhase", name: "Sources", of: targetID)
            let built = objects[sources]?.list("files").compactMap { objects[$0] } ?? []
            if built.contains(where: { $0.string("fileRef") == reference }) { continue }
            let buildFile = freshID()
            try insert("\t\t\(buildFile) /* \(fileName) in Sources */ = {isa = PBXBuildFile; fileRef = \(reference) /* \(fileName) */; };\n", isa: "PBXBuildFile")
            try append("\(buildFile) /* \(fileName) in Sources */", to: "files", of: sources)
        }
        return text != before
    }

    /// The classic group of the folder `folders` (relative to the project's folder), made under the deepest group
    /// that already stands for part of it.
    private mutating func group(for folders: [String]) throws -> String {
        guard let main = project?.string("mainGroup") else { throw GraniteError.refused(["the project file has no main group"]) }
        var paths = groupPaths
        var current = main
        var depth = 0
        // The deepest classic group whose folder is a prefix of the file's.
        for (id, path) in paths where objects[id]?.isa == "PBXGroup" {
            let parts = path.isEmpty ? [] : path.split(separator: "/").map(String.init)
            if parts.count > depth, parts.count <= folders.count, Array(folders.prefix(parts.count)) == parts {
                current = id
                depth = parts.count
            }
        }
        for folder in folders.dropFirst(depth) {
            let id = freshID()
            try insert("\t\t\(id) /* \(folder) */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t);\n\t\t\tpath = \(Self.quoted(folder));\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n",
                       isa: "PBXGroup")
            try append("\(id) /* \(folder) */", to: "children", of: current)
            current = id
            paths = groupPaths
        }
        return current
    }
}

extension Pbxproj {
    /// The folder, relative to the project's, of the first Swift file the target compiles from a classic group.
    func folderOfFirstSource(of targetID: String) -> String? {
        guard let target = targets.first(where: { $0.id == targetID }), let sources = phase("PBXSourcesBuildPhase", of: target) else { return nil }
        let paths = groupPaths
        for buildFile in sources.list("files").compactMap({ objects[$0] }) {
            guard let reference = buildFile.string("fileRef") else { continue }
            if let group = objects("PBXGroup").first(where: { $0.list("children").contains(reference) }), let path = paths[group.id] { return path }
        }
        return nil
    }
}
