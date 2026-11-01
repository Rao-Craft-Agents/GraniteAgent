//  WHAT: The files every Granite app starts from: the `@main` App, the two-platform delegate, the menu commands, the
//        root that holds the relays and boots the app, the modal host the root view applies, and the `.gitignore`.
//  PIN:  BOOT FROM THE ROOT VIEW, GATED ON `isLoaded`. A persisted store restores after its service exists, so the
//        app boots once the settings have loaded (skill rule 7), never from `App.init`.

import Foundation

enum AppTemplates {
    static func app(name: String, root: String) -> String {
        """
        import Granite
        import SwiftUI

        @main
        struct \(appType(name)): App {
            #if os(iOS)
            @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
            #elseif os(macOS)
            @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
            #endif

            init() {
                // Granite logs each store's restore at debug level; the app keeps its errors only.
                GraniteLogger.currentLevel = .error
            }

            var body: some Scene {
                WindowGroup {
                    \(root)()
                }
                #if os(macOS)
                .commands { AppCommands() }
                #endif
            }
        }

        """
    }

    /// `Recipes` → `RecipesApp`; a name that already ends in App stays as it is.
    static func appType(_ name: String) -> String { name.hasSuffix("App") ? name : name + "App" }

    static let delegate = """
        //  Platform lifecycle only: the app's state lives in its services, and boot starts from the root view once the
        //  settings have loaded.

        import SwiftUI

        #if os(iOS)
        import UIKit

        final class AppDelegate: NSObject, UIApplicationDelegate {
            func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
                true
            }
        }
        #elseif os(macOS)
        import AppKit

        final class AppDelegate: NSObject, NSApplicationDelegate {
            func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
                true
            }
        }
        #endif

        """

    static let commands = """
        import SwiftUI

        /// The app's own menu commands, beside the system's.
        struct AppCommands: Commands {
            var body: some Commands {
                EmptyCommands()
            }
        }

        """

    static let root = """
        import Foundation
        import Granite
        import GraniteAgents

        /// The app's root: one relay to every service, held for the life of the process. Boot and long-running work
        /// start here, and AppKit, menus and the delegate reach the services through it.
        @MainActor
        final class AppRoot {
            static let shared = AppRoot()

            @Relay(.silence) var environment: EnvironmentService
            @Relay(.silence) var config: ConfigService

            private init() {}

            /// Boots the app once its settings have loaded: counts the launch, then marks the environment ready. A boot
            /// that failed may run again; one that is ready does nothing.
            func boot() async {
                let phase = environment.state.phase
                guard phase != .ready else { return }
                // Read before the launch is counted: the settings' writer commits in the turn it is sent.
                let isFirstLaunch = config.state.launches == 0
                if phase == .idle { config.set(.launched(Date())) }
                do {
                    try await environment.boot(isFirstLaunch: isFirstLaunch)

                } catch {
                    environment.set(.failed(error.localizedDescription))
                }
            }
        }

        """

    /// The modal host before the app has a modal service: the root view applies it, and it changes nothing.
    static let modalHostingInert = """
        import SwiftUI

        extension View {
            /// Hosts the app's sheets, alerts, toasts and panels over this view. The root view applies it once; until
            /// the app has a modal service it changes nothing.
            func modalHosted() -> some View {
                self
            }
        }

        """

    static let gitignore = """
        .DS_Store
        DerivedData/
        *.xcuserstate
        xcuserdata/
        .swiftpm/
        .build/

        """

    static let assetsContents = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """

    static let accentColor = """
        {
          "colors" : [
            {
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0.580",
                  "green" : "0.250",
                  "red" : "0.290"
                }
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0.910",
                  "green" : "0.620",
                  "red" : "0.640"
                }
              },
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """

    /// An app icon set with every slot and no picture yet: the `assets` agent draws the icon.
    static let appIcon: String = {
        var images = [#"    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }"#,
                      #"    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }"#,
                      #"    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ], "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }"#]
        for size in ["16x16", "32x32", "128x128", "256x256", "512x512"] {
            for scale in ["1x", "2x"] { images.append(#"    { "idiom" : "mac", "scale" : "\#(scale)", "size" : "\#(size)" }"#) }
        }
        return "{\n  \"images\" : [\n" + images.joined(separator: ",\n") + "\n  ],\n  \"info\" : {\n    \"author\" : \"xcode\",\n    \"version\" : 1\n  }\n}\n"
    }()

    static func uiTests(name: String) -> String {
        """
        import XCTest

        /// The app as a person meets it: launched, and on screen.
        final class \(name)UITests: XCTestCase {
            override func setUpWithError() throws {
                continueAfterFailure = false
            }

            @MainActor
            func testLaunches() throws {
                let app = XCUIApplication()
                app.launch()
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
            }
        }

        """
    }
}
