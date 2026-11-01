//  WHAT: The root page: it boots the app once the settings have loaded, shows a spinner while it starts, the reason
//        and a retry when it failed, and the app when it is ready; it applies the appearance and hosts the modals.
//        Three readies: a first screen (a new project), the view the app had before (a linked project), and the
//        app's navigation (after `make: navigation`).

import Foundation

enum RootTemplates {
    enum Ready {
        /// A new app's first screen: its name.
        case welcome(String)
        /// The view the app had before Granite, passed in.
        case content
        /// The app's destinations.
        case navigation
    }

    static func component(_ root: String, hostsContent: Bool) -> String {
        var text = """
            import Granite
            import SwiftUI

            /// The app's root page: it boots the app once the settings have loaded, and shows the app when it is ready.
            struct \(root): GraniteComponent {
                @Command var center: Center

                @Relay var environment: EnvironmentService
                @Relay var config: ConfigService
            """
        if hostsContent {
            text += """


                    /// What the app shows once it is ready: the view it had before Granite.
                    let content: () -> AnyView

                    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
                        self.content = { AnyView(content()) }
                    }
                """
        }
        return text + "\n}\n"
    }

    static func center(_ root: String) -> String {
        """
        import Granite

        extension \(root) {
            struct Center: GraniteCenter {
                struct State: GraniteState {}

                @Store var state: State
            }
        }

        """
    }

    static func view(_ root: String, ready: Ready) -> String {
        let readyView: String
        switch ready {
        case .welcome(let name):
            readyView = """
                                NavigationStack {
                                    ContentUnavailableView("\(SwiftName.escaped(name))", systemImage: "square.grid.2x2", description: Text("Everything is in place."))
                                }
                """
        case .content:
            readyView = "                content()"
        case .navigation:
            readyView = "                PlatformNavigationView()"
        }
        return """
            import Granite
            import SwiftUI

            extension \(root): View {
                var view: some View {
                    Group {
                        switch environment.state.phase {
                        case .idle:
                            ProgressView("Starting…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .ready:
            \(readyView)
                        case .failed:
                            ContentUnavailableView {
                                Label("Couldn’t Start", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text(environment.state.lastError ?? String(localized: "Something went wrong while starting."))
                            } actions: {
                                Button("Try Again") {
                                    Task { await AppRoot.shared.boot() }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .preferredColorScheme(config.state.appearance.colorScheme)
                    .modalHosted()
                    .task(id: config.isLoaded) {
                        guard config.isLoaded else { return }
                        await AppRoot.shared.boot()
                    }
                }
            }

            """
    }
}
