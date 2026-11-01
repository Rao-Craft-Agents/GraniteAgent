import Foundation

/// Where a make writes a service or a page: into the app, or into a kit (a Swift package) the folder sits in.
struct Placement {
    /// The folder the files go in.
    let folder: URL
    /// The kit, when the folder is inside one: its types are then public and its tests are the package's.
    let package: PackageInfo?

    /// The folder for `type` under `kind` (`Services`, `Components`): `into` read from the host's folder, the type's
    /// own folder added when `into` names the folder it goes in rather than its own; a package's root leads to its
    /// sources.
    static func resolve(into: String?, type: String, kind: String, workspace: Workspace) -> Placement {
        if let into, !into.trimmingCharacters(in: .whitespaces).isEmpty {
            var folder = workspace.files.resolve(into)
            if FileManager.default.fileExists(atPath: folder.appendingPathComponent("Package.swift").path) {
                let package = PackageInfo(root: folder)
                return Placement(folder: package.sources.appendingPathComponent("\(kind)/\(type)"), package: package)
            }
            if folder.lastPathComponent != type { folder = folder.appendingPathComponent(type) }
            return Placement(folder: folder, package: workspace.package(containing: folder.deletingLastPathComponent()))
        }
        if workspace.project == nil, FileManager.default.fileExists(atPath: workspace.root.appendingPathComponent("Package.swift").path) {
            let package = PackageInfo(root: workspace.root)
            return Placement(folder: package.sources.appendingPathComponent("\(kind)/\(type)"), package: package)
        }
        let layout = AppLayout.detect(workspace)
        return Placement(folder: (kind == "Services" ? layout.services : layout.components).appendingPathComponent(type), package: nil)

    }
}
