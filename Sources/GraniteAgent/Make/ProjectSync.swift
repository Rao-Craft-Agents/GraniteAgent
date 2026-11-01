//  WHAT: The last step of a call that writes into an app: each new Swift file joins the targets it belongs to. In a
//        project of synchronized folders that is nothing; in one of classic groups, a file reference and a build file
//        a target. The project file is then checked as a property list before anything lands.

import Foundation

enum ProjectSync {
    static func include(_ plan: inout Plan, in workspace: Workspace) throws {
        guard let url = workspace.pbxprojURL else { return }
        let original = plan.text(at: url) ?? (try? String(contentsOf: url, encoding: .utf8))
        guard let original else { return }
        var project = try Pbxproj(original)
        let apps = project.applicationTargets.map(\.id)
        let tests = project.targets.filter(\.isUnitTests).map(\.id)
        var changed = false
        for file in plan.files where file.url.pathExtension == "swift" {
            guard let path = workspace.relativeToRoot(file.url) else { continue }
            switch file.role {
            case .app: changed = try project.include(path, in: apps) || changed
            case .tests: changed = try project.include(path, in: tests) || changed
            case .other: continue
            }
        }
        if changed || plan.text(at: url) != nil {
            if let failure = Pbxproj.lint(project.text) { throw GraniteError.refused(["the edited project file does not read: \(failure)"]) }
        }
        if changed {
            plan.write(url, project.text, role: .other)
            plan.notes.append("added the new files to \(workspace.project?.lastPathComponent ?? "the project")'s groups and targets")
        }
    }
}
