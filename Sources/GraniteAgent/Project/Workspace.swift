//  WHAT: Where a call works: the host's folder, the app or package in it (the folder with the `.xcodeproj` or the
//        `Package.swift`, the host's own or the one folder below it that has one), and what its project file says
//        of it: the app's name, the module its code compiles into, its targets and where its tests go.

import Foundation

struct Workspace {
    let files: AgentFiles
    /// The app's or the package's folder.
    let root: URL
    /// The Xcode project, when the root has one.
    let project: URL?

    init(directory: String?) {
        files = AgentFiles(directory: directory)
        let base = files.root
        if let found = Self.project(in: base) {
            root = base; project = found
        } else if FileManager.default.fileExists(atPath: base.appendingPathComponent("Package.swift").path) {
            root = base; project = nil
        } else {
            let below = Self.contents(of: base)
                .filter { !$0.lastPathComponent.hasPrefix(".") }
                .compactMap { folder -> (URL, URL)? in Self.project(in: folder).map { (folder, $0) } }
            if below.count == 1 { root = below[0].0; project = below[0].1 } else { root = base; project = nil }
        }
    }

    /// The one `.xcodeproj` in `folder`, if it has exactly one.
    static func project(in folder: URL) -> URL? {
        let found = contents(of: folder).filter { $0.pathExtension == "xcodeproj" }
        return found.count == 1 ? found[0] : nil
    }

    /// What `folder` holds, named from `folder` as the host wrote it (never through a resolved link).
    static func contents(of folder: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []).sorted().map { folder.appendingPathComponent($0) }
    }

    var pbxprojURL: URL? { project?.appendingPathComponent("project.pbxproj") }

    /// The app's name, as its project is named.
    var appName: String? { project?.deletingPathExtension().lastPathComponent }

    /// `path` relative to the app's folder when inside it.
    func relativeToRoot(_ url: URL) -> String? {
        let base = root.path.hasSuffix("/") ? root.path : root.path + "/"
        return url.path.hasPrefix(base) ? String(url.path.dropFirst(base.count)) : nil
    }

    /// `path` read from the app's folder.
    func inRoot(_ path: String) -> URL { URL(fileURLWithPath: AgentFiles.resolvingParents(root.path + "/" + path)) }

    /// The project file, read.
    func pbxproj() throws -> Pbxproj? {
        guard let url = pbxprojURL else { return nil }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw GraniteError.refused(["\(files.relative(url)) cannot be read"])
        }
        return try Pbxproj(text)
    }

    /// The package `folder` sits in: the nearest folder at or above it, inside the host's, with a `Package.swift`.
    func package(containing folder: URL) -> PackageInfo? {
        var current = folder
        let top = files.root.path
        while current.path.hasPrefix(top) {
            let manifest = current.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: manifest.path) { return PackageInfo(root: current) }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return nil
    }
}

extension Workspace {
    /// The app's unit tests' folder and the module they `@testable import`, when the project has a unit-test target:
    /// its synchronized folder, or the folder its first test file is in.
    func unitTests() throws -> (folder: URL, module: String)? {
        guard let project = try pbxproj(), let app = project.applicationTargets.first else { return nil }
        let module = project.moduleName(of: app)
        for target in project.targets where target.isUnitTests {
            if let folder = project.synchronizedFolders(of: target).first { return (inRoot(folder), module) }
            if let folder = project.folderOfFirstSource(of: target.id) { return (inRoot(folder), module) }
        }
        return nil
    }

    /// The root that holds the app's relays, with `service` added; nil when it holds it already or there is none.
    func rootAdding(_ service: String, as name: String? = nil, index: ProjectIndex, plan: Plan) -> (URL, String)? {
        guard let file = index.appRoot, let text = plan.text(at: file) ?? (try? String(contentsOf: file, encoding: .utf8)),
              let edited = RootEditor.adding(service, as: name ?? SwiftName.relayName(service), isPublic: false, to: text) else { return nil }

        return (file, edited)
    }
}
