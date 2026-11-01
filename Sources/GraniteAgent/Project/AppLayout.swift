//  WHAT: Where an app keeps its parts. A project this package made is in the Loom layout (Shared, Services,
//        Components, iOS and macOS at its root); a project it linked keeps everything in the folder of its `@main`
//        App, so its parts go in that folder's Services, Components, Utility, iOS and macOS.

import Foundation

struct AppLayout {
    /// The folder the app's own Swift lives in: the root in the Loom layout, the `@main` App's folder otherwise.
    let source: URL
    /// Whether the app is in the Loom layout.
    let isLoom: Bool
    /// The `@main` App's file, when there is one.
    let app: URL?

    var shared: URL { isLoom ? source.appendingPathComponent("Shared") : source }
    var utility: URL { shared.appendingPathComponent("Utility") }
    var services: URL { source.appendingPathComponent("Services") }
    var components: URL { source.appendingPathComponent("Components") }
    var ios: URL { source.appendingPathComponent("iOS") }
    var macos: URL { source.appendingPathComponent("macOS") }

    static func detect(_ workspace: Workspace) -> AppLayout {
        let root = workspace.root
        let manager = FileManager.default
        let loomApp = root.appendingPathComponent("Shared/App.swift")
        if manager.fileExists(atPath: loomApp.path) { return AppLayout(source: root, isLoom: true, app: loomApp) }
        if let app = mainApp(under: root) { return AppLayout(source: app.deletingLastPathComponent(), isLoom: false, app: app) }
        return AppLayout(source: root, isLoom: manager.fileExists(atPath: root.appendingPathComponent("Shared").path), app: nil)
    }

    /// The file declaring the `@main` App, outside build products, packages and tests.
    static func mainApp(under root: URL) -> URL? {
        let skipped: Set<String> = [".build", ".git", "DerivedData", "Packages"]
        for url in ProjectIndex.swiftFiles(under: root, skipping: skipped) {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if text.range(of: #"(?m)^@main\s*\n?\s*struct\s+\w+\s*:\s*App\b"#, options: .regularExpression) != nil { return url }
        }
        return nil
    }
}
