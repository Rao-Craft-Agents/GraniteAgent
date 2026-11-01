//  WHAT: An Xcode project file as text, with the reads and the edits the makes need: targets and their phases,
//        groups and their paths, package references and build settings.
//  PIN:  TEXT EDITS, IN XCODE'S OWN FORM. The file is never re-serialized: an edit inserts lines where Xcode would
//        have written them (an object in its section, an item in a list), so a diff shows only what was added and
//        Xcode reads the file back unchanged.
//  PIN:  FRESH IDS NEVER COLLIDE. A new object's id is 24 hex digits drawn at random and checked against every id
//        already in the file.

import Foundation

struct Pbxproj: Sendable {
    private(set) var text: String
    private(set) var objects: [String: PbxObject] = [:]
    /// The objects' ids in the order the file has them.
    private(set) var order: [String] = []
    private(set) var rootObject = ""

    init(_ text: String) throws {
        self.text = text
        try reparse()
    }

    /// Reads the file again after an edit.
    mutating func reparse() throws {
        var reader = PlistReader(Array(text.utf8))
        let parsed = try reader.document()
        objects = [:]
        order = []
        for object in parsed.objects {
            objects[object.id] = object
            order.append(object.id)
        }
        rootObject = parsed.root["rootObject"]?.string ?? ""
    }

    var project: PbxObject? { objects[rootObject] }

    /// The objects of one kind, in file order.
    func objects(_ isa: String) -> [PbxObject] { order.compactMap { objects[$0] }.filter { $0.isa == isa } }

    // MARK: - Targets

    struct Target: Sendable {
        let id: String
        let name: String
        let productType: String
        let object: PbxObject

        var isApplication: Bool { productType == "com.apple.product-type.application" }
        var isUnitTests: Bool { productType == "com.apple.product-type.bundle.unit-test" }
    }

    var targets: [Target] {
        (project?.list("targets") ?? []).compactMap { id in
            guard let object = objects[id], object.isa == "PBXNativeTarget" else { return nil }
            return Target(id: id, name: object.string("name") ?? id, productType: object.string("productType") ?? "", object: object)
        }
    }

    var applicationTargets: [Target] { targets.filter(\.isApplication) }

    /// The target's build phase of a kind (`PBXSourcesBuildPhase`), if it has one.
    func phase(_ isa: String, of target: Target) -> PbxObject? {
        target.object.list("buildPhases").compactMap { objects[$0] }.first { $0.isa == isa }
    }

    /// The target's build settings in a configuration (`Debug` when left out).
    func settings(of target: Target, configuration: String = "Debug") -> PlistValue? {
        guard let list = target.object.string("buildConfigurationList").flatMap({ objects[$0] }) else { return nil }
        let configurations = list.list("buildConfigurations").compactMap { objects[$0] }
        let chosen = configurations.first { $0.string("name") == configuration } ?? configurations.first
        return chosen?.value["buildSettings"]
    }

    /// The module the target's code is compiled into: its product name, `$(TARGET_NAME)` read as the target's name,
    /// with what a module name cannot hold made an underscore.
    func moduleName(of target: Target) -> String {
        let settings = settings(of: target)
        var name = settings?["PRODUCT_MODULE_NAME"]?.string ?? settings?["PRODUCT_NAME"]?.string ?? "$(TARGET_NAME)"
        name = name.replacingOccurrences(of: "$(TARGET_NAME)", with: target.name).replacingOccurrences(of: "${TARGET_NAME}", with: target.name)
        var module = String(name.map { $0.isLetter || $0.isNumber || $0 == "_" ? $0 : "_" })
        if let first = module.first, first.isNumber { module = "_" + module }
        return module
    }

    // MARK: - Groups

    /// Every group's folder, relative to the project's folder: classic groups and synchronized folders alike.
    var groupPaths: [String: String] {
        guard let main = project?.string("mainGroup") else { return [:] }
        var paths: [String: String] = [main: ""]
        var stack = [main]
        while let id = stack.popLast() {
            guard let group = objects[id], let base = paths[id] else { continue }
            for child in group.list("children") {
                guard let object = objects[child], object.isa == "PBXGroup" || object.isa == "PBXFileSystemSynchronizedRootGroup" else { continue }
                let path = object.string("path")
                let tree = object.string("sourceTree") ?? "<group>"
                if let path {
                    paths[child] = tree == "SOURCE_ROOT" ? path : (base.isEmpty ? path : base + "/" + path)
                } else {
                    paths[child] = base
                }
                stack.append(child)
            }
        }
        return paths
    }

    /// The folders, relative to the project's, that are synchronized into `target`: a file under one joins it.
    func synchronizedFolders(of target: Target) -> [String] {
        let paths = groupPaths
        return target.object.list("fileSystemSynchronizedGroups").compactMap { paths[$0] }
    }

    // MARK: - Ids

    /// A new object id: 24 hex digits that no object in the file has, nor any id drawn before it in this edit.
    mutating func freshID() -> String {
        while true {
            let high = UInt64.random(in: 0...UInt64.max), low = UInt32.random(in: 0...UInt32.max)
            let id = (String(format: "%016llX", high) + String(format: "%08X", low))
            if !text.contains(id) && !drawn.contains(id) { drawn.insert(id); return id }
        }
    }
    private var drawn: Set<String> = []

    // MARK: - Edits

    /// Puts `entry` (the object's whole text, tab-indented, ending with a newline) in its section, making the
    /// section where Xcode would when the file has none.
    mutating func insert(_ entry: String, isa: String) throws {
        let end = "/* End \(isa) section */"
        if let range = text.range(of: end) {
            text.insert(contentsOf: entry, at: range.lowerBound)
        } else {
            let section = "/* Begin \(isa) section */\n" + entry + end + "\n\n"
            let sections = text.ranges(of: #"/\* Begin (\w+) section \*/"#)
            if let next = sections.first(where: { String(text[$0]).dropFirst(9).prefix(while: { $0 != " " }) > Substring(isa) }) {
                text.insert(contentsOf: section, at: next.lowerBound)
            } else if let close = text.range(of: "\t};\n\trootObject") {
                text.insert(contentsOf: "\n" + section.dropLast(), at: close.lowerBound)
            } else {
                throw GraniteError.refused(["the project file has no objects section to add \(isa) to"])
            }
        }
        try reparse()
    }

    /// Adds `item` (an id and its comment) to the list `key` of the object `id`, making the list when it has none.
    /// Does nothing when the list holds the id already.
    mutating func append(_ item: String, to key: String, of id: String) throws {
        guard let object = objects[id] else { throw GraniteError.refused(["the project file has no object \(id)"]) }
        let itemID = String(item.prefix { !$0.isWhitespace })
        if object.list(key).contains(itemID) { return }
        let bytes = Array(text.utf8)
        let objectText = String(decoding: bytes[object.range], as: UTF8.self)
        var edited: String
        if let open = objectText.range(of: "\n\t\t\t\(key) = (\n") {
            guard let close = objectText.range(of: "\t\t\t);", range: open.upperBound..<objectText.endIndex) else {
                throw GraniteError.refused(["the project file's \(key) list of \(id) is not closed"])
            }
            edited = objectText
            edited.insert(contentsOf: "\t\t\t\t\(item),\n", at: close.lowerBound)
        } else if let open = objectText.range(of: "\n\t\t\t\(key) = ();") {
            edited = objectText.replacingCharacters(in: open, with: "\n\t\t\t\(key) = (\n\t\t\t\t\(item),\n\t\t\t);")
        } else if let last = objectText.range(of: "\t\t};", options: .backwards) {
            edited = objectText
            edited.insert(contentsOf: "\t\t\t\(key) = (\n\t\t\t\t\(item),\n\t\t\t);\n", at: last.lowerBound)
        } else {
            throw GraniteError.refused(["the project file's object \(id) is not one Xcode wrote"])
        }
        replace(object.range, with: edited)
        try reparse()
    }

    /// Sets a build setting in the configuration `id`, replacing its value when it has one.
    mutating func setBuildSetting(_ key: String, to value: String, in id: String) throws {
        guard let object = objects[id] else { throw GraniteError.refused(["the project file has no configuration \(id)"]) }
        let bytes = Array(text.utf8)
        var objectText = String(decoding: bytes[object.range], as: UTF8.self)
        let line = "\t\t\t\t\(key) = \(value);\n"
        if let existing = objectText.range(of: #"\t\t\t\t\#(key) = [^;\n]*;\n"#, options: .regularExpression) {
            objectText.replaceSubrange(existing, with: line)
        } else if let open = objectText.range(of: "buildSettings = {\n") {
            objectText.insert(contentsOf: line, at: open.upperBound)
        } else {
            throw GraniteError.refused(["the configuration \(id) has no build settings"])
        }
        replace(object.range, with: objectText)
        try reparse()
    }

    private mutating func replace(_ range: Range<Int>, with replacement: String) {
        var bytes = Array(text.utf8)
        bytes.replaceSubrange(range, with: Array(replacement.utf8))
        text = String(decoding: bytes, as: UTF8.self)
    }

    /// Whether the file reads as a property list: `plutil -lint`, the check Xcode's own reader would make.
    static func lint(_ text: String) -> String? {
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/plutil") else { return nil }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("granite-lint-\(UUID().uuidString.prefix(8)).pbxproj")
        defer { try? FileManager.default.removeItem(at: file) }
        guard (try? Data(text.utf8).write(to: file)) != nil else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/plutil")
        process.arguments = ["-lint", "-s", file.path]
        let errors = Pipe()
        process.standardOutput = errors
        process.standardError = errors
        process.standardInput = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = errors.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return process.terminationStatus == 0 ? nil : String(decoding: data, as: UTF8.self)
    }
}

private extension String {
    func ranges(of pattern: String) -> [Range<String.Index>] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: self, range: NSRange(startIndex..., in: self)).compactMap { Range($0.range, in: self) }
    }
}
