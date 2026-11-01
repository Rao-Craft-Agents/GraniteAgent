//  WHAT: A new app's Xcode project, adapted from Granite's template: objectVersion 77 with synchronized folders
//        (Shared, Components, Services, iOS, macOS for the apps; Tests and UITests for their test targets), an app
//        target, a unit-test target hosted by it and a UI-test target per platform, Swift 5 language mode (reducers
//        hold relays), iOS 17 and macOS 14, a generated Info.plist; and the shared schemes that build and test them.
//  PIN:  A FILE UNDER A SYNCHRONIZED FOLDER JOINS ITS TARGETS WITH NO EDIT. Every later call writes into these
//        folders and leaves the project file alone; only packages are edited in.

import Foundation

enum XcodeTemplates {
    /// The tokens a project's objects are named by in `project`, each given a fresh id.
    static let tokens = ["PROJECT", "MAIN", "PRODUCTS",
                         "APP_IOS", "APP_MAC", "TESTS_IOS", "TESTS_MAC", "UITESTS_IOS", "UITESTS_MAC",
                         "PRODUCT_APP_IOS", "PRODUCT_APP_MAC", "PRODUCT_TESTS_IOS", "PRODUCT_TESTS_MAC", "PRODUCT_UITESTS_IOS", "PRODUCT_UITESTS_MAC",
                         "SYNC_SHARED", "SYNC_COMPONENTS", "SYNC_SERVICES", "SYNC_IOS", "SYNC_MACOS", "SYNC_TESTS", "SYNC_UITESTS",
                         "PROXY_TESTS_IOS", "PROXY_TESTS_MAC", "PROXY_UITESTS_IOS", "PROXY_UITESTS_MAC",
                         "DEP_TESTS_IOS", "DEP_TESTS_MAC", "DEP_UITESTS_IOS", "DEP_UITESTS_MAC",
                         "LIST_PROJECT", "LIST_APP_IOS", "LIST_APP_MAC", "LIST_TESTS_IOS", "LIST_TESTS_MAC", "LIST_UITESTS_IOS", "LIST_UITESTS_MAC",
                         "CFG_PROJECT_DEBUG", "CFG_PROJECT_RELEASE", "CFG_APP_IOS_DEBUG", "CFG_APP_IOS_RELEASE", "CFG_APP_MAC_DEBUG", "CFG_APP_MAC_RELEASE",
                         "CFG_TESTS_IOS_DEBUG", "CFG_TESTS_IOS_RELEASE", "CFG_TESTS_MAC_DEBUG", "CFG_TESTS_MAC_RELEASE",
                         "CFG_UITESTS_IOS_DEBUG", "CFG_UITESTS_IOS_RELEASE", "CFG_UITESTS_MAC_DEBUG", "CFG_UITESTS_MAC_RELEASE"]
        + ["APP_IOS", "APP_MAC", "TESTS_IOS", "TESTS_MAC", "UITESTS_IOS", "UITESTS_MAC"].flatMap { ["SRC_\($0)", "FW_\($0)", "RES_\($0)"] }

    /// The project file, its objects named by `id` (a token → a fresh id).
    static func project(name: String, bundleId: String, team: String, id: (String) -> String) -> String {
        let q = Pbxproj.quoted
        var text = projectTemplate
        for token in tokens { text = text.replacingOccurrences(of: "@@\(token)@@", with: id(token)) }
        return text
            .replacingOccurrences(of: "@@NAME_Q@@", with: q(name))
            .replacingOccurrences(of: "@@NAME@@", with: name)
            .replacingOccurrences(of: "@@BUNDLE@@", with: q(bundleId))
            .replacingOccurrences(of: "@@TESTS_BUNDLE@@", with: q(bundleId + ".tests"))
            .replacingOccurrences(of: "@@UITESTS_BUNDLE@@", with: q(bundleId + ".uitests"))
            .replacingOccurrences(of: "@@TEAM@@", with: "\"\(team)\"")
            // PIN: NO TEAM, SIGNED TO RUN LOCALLY. A Mac app with no team builds and runs on this Mac only when it is
            // signed ad hoc; automatic signing with no team refuses. The Mac app is also the project's first target,
            // so a build that names no scheme builds the app that needs no team.
            .replacingOccurrences(of: "@@MAC_SIGN@@\n", with: team.isEmpty ? "\t\t\t\tCODE_SIGN_IDENTITY = \"-\";\n" : "")
            .replacingOccurrences(of: "@@DISPLAY@@", with: "\"\(name)\"")
    }

    static let workspace = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace
           version = "1.0">
           <FileRef
              location = "self:">
           </FileRef>
        </Workspace>

        """

    /// The shared scheme of one platform: builds its app, runs it, and tests it with its unit and UI tests.
    static func scheme(name: String, platform: String, app: String, tests: String, uiTests: String) -> String {
        func reference(_ id: String, _ buildable: String, _ blueprint: String, indent: String) -> String {
            """
            \(indent)<BuildableReference
            \(indent)   BuildableIdentifier = "primary"
            \(indent)   BlueprintIdentifier = "\(id)"
            \(indent)   BuildableName = "\(buildable)"
            \(indent)   BlueprintName = "\(blueprint)"
            \(indent)   ReferencedContainer = "container:\(name).xcodeproj">
            \(indent)</BuildableReference>
            """
        }
        let appReference = { (indent: String) in reference(app, "\(name).app", "\(name)-\(platform)", indent: indent) }
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <Scheme
               LastUpgradeVersion = "2660"
               version = "1.7">
               <BuildAction
                  parallelizeBuildables = "YES"
                  buildImplicitDependencies = "YES"
                  buildArchitectures = "Automatic">
                  <BuildActionEntries>
                     <BuildActionEntry
                        buildForTesting = "YES"
                        buildForRunning = "YES"
                        buildForProfiling = "YES"
                        buildForArchiving = "YES"
                        buildForAnalyzing = "YES">
            \(appReference("            "))
                     </BuildActionEntry>
                  </BuildActionEntries>
               </BuildAction>
               <TestAction
                  buildConfiguration = "Debug"
                  selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
                  selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
                  shouldUseLaunchSchemeArgsEnv = "YES">
                  <Testables>
                     <TestableReference
                        skipped = "NO"
                        parallelizable = "NO">
            \(reference(tests, "\(name)Tests.xctest", "\(name)Tests-\(platform)", indent: "            "))
                     </TestableReference>
                     <TestableReference
                        skipped = "YES"
                        parallelizable = "NO">
            \(reference(uiTests, "\(name)UITests.xctest", "\(name)UITests-\(platform)", indent: "            "))
                     </TestableReference>
                  </Testables>
               </TestAction>
               <LaunchAction
                  buildConfiguration = "Debug"
                  selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
                  selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
                  launchStyle = "0"
                  useCustomWorkingDirectory = "NO"
                  ignoresPersistentStateOnLaunch = "NO"
                  debugDocumentVersioning = "YES"
                  debugServiceExtension = "internal"
                  allowLocationSimulation = "YES">
                  <BuildableProductRunnable
                     runnableDebuggingMode = "0">
            \(appReference("         "))
                  </BuildableProductRunnable>
               </LaunchAction>
               <ProfileAction
                  buildConfiguration = "Release"
                  shouldUseLaunchSchemeArgsEnv = "YES"
                  savedToolIdentifier = ""
                  useCustomWorkingDirectory = "NO"
                  debugDocumentVersioning = "YES">
                  <BuildableProductRunnable
                     runnableDebuggingMode = "0">
            \(appReference("         "))
                  </BuildableProductRunnable>
               </ProfileAction>
               <AnalyzeAction
                  buildConfiguration = "Debug">
               </AnalyzeAction>
               <ArchiveAction
                  buildConfiguration = "Release"
                  revealArchiveInOrganizer = "YES">
               </ArchiveAction>
            </Scheme>

            """
    }
}
