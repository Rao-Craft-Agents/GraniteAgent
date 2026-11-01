//  WHAT: `make: modals`: ModalService (sheets, alerts, toasts, travelling panels, Mac windows), its host views, and
//        `modalHosted()` made real, so the root view that applies it presents them.

import Foundation

struct ModalsMake {
    let input: GraniteAppAgent.Input
    let workspace: Workspace

    func plan() throws -> Plan {
        guard workspace.project != nil else {
            throw GraniteError.refused(["modals are an app's: call it in the folder with the app's .xcodeproj"])
        }
        let index = ProjectIndex(root: workspace.root)
        let layout = AppLayout.detect(workspace)
        var plan = Plan()
        for (path, text) in ModalTemplates.service {
            plan.write(layout.services.appendingPathComponent("ModalService/\(path)"), text)
        }
        let hosting = index.swiftFiles.first { url in
            (try? String(contentsOf: url, encoding: .utf8))?.contains("func modalHosted()") == true
        } ?? layout.utility.appendingPathComponent("ModalHosting.swift")
        plan.write(hosting, ModalTemplates.hosting)
        if let (folder, module) = try workspace.unitTests() {
            plan.write(folder.appendingPathComponent("ModalOpsTests.swift"), ModalTemplates.tests(module: module), role: .tests)
        }
        if !index.hasRelayClock { plan.write(layout.utility.appendingPathComponent("RelayClock.swift"), UtilityTemplates.relayClock) }
        if let (file, text) = workspace.rootAdding("ModalService", as: "modals", index: index, plan: plan) { plan.write(file, text) }

        plan.types = ["ModalService", "ModalHosting", "ModalSheetHost", "ModalAlertHost", "ModalToastView", "ModalPanelView"]
        plan.notes.append("present from any page or service: `modals.sheet(id: \"compose\", detents: [.medium, .large]) { … }`, `modals.alert(ModalAlert(title: …))`, `modals.toast(\"Saved\", style: .success)`, `modals.travel(id: \"draft\", title: \"Draft\") { … }`, and on the Mac `modals.window(id:title:) { … }`")
        if !(index.swiftFiles.contains { (try? String(contentsOf: $0, encoding: .utf8))?.contains(".modalHosted()") == true }) {
            plan.notes.append("no view applies `.modalHosted()` yet: the root view applies it once, so the modals show")
        }
        return plan
    }
}
