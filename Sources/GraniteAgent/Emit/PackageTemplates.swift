//  WHAT: A kit: a Swift package of Granite services an app links (or a command line drives), with its root that
//        holds a relay to each of its services, and its test target. Granite at the app's revision, Swift 5
//        language mode (its reducers hold relays, skill rule 9), iOS 17 and macOS 14.

import Foundation

enum PackageTemplates {
    static func manifest(name: String, packages: [PackageDependency]) -> String {
        var dependencies = ["        .package(url: \"\(GranitePin.url)\", revision: \"\(GranitePin.revision)\"),"]
        var products = ["                .product(name: \"Granite\", package: \"Granite\"),", "                .product(name: \"GraniteAgents\", package: \"Granite\"),"]
        for package in packages {
            switch package.requirement {
            case .revision(let revision): dependencies.append("        .package(url: \"\(package.url)\", revision: \"\(revision)\"),")
            case .exact(let version): dependencies.append("        .package(url: \"\(package.url)\", exact: \"\(version)\"),")
            }
            products += package.products.map { "                .product(name: \"\($0)\", package: \"\(package.identity)\")," }
        }
        return """
            // swift-tools-version:6.0
            // \(name): services an app on Granite shares, with the root that holds them.

            import PackageDescription

            let package = Package(
                name: "\(name)",
                platforms: [.iOS(.v17), .macOS(.v14)],
                products: [
                    .library(name: "\(name)", targets: ["\(name)"]),
                ],
                dependencies: [
            \(dependencies.joined(separator: "\n"))
                ],
                targets: [
                    .target(
                        name: "\(name)",
                        dependencies: [
            \(products.joined(separator: "\n"))
                        ],
                        swiftSettings: [.swiftLanguageMode(.v5)]),
                    .testTarget(
                        name: "\(name)Tests",
                        dependencies: ["\(name)"],
                        swiftSettings: [.swiftLanguageMode(.v5)]),
                ]
            )

            """
    }

    static func root(name: String) -> String {
        """
        import Granite

        /// \(name)'s root: one relay to every service the kit keeps, held for the life of the process. An app or a
        /// command line reaches the kit's services through it.
        @MainActor
        public final class \(name)Root {
            public static let shared = \(name)Root()

            private init() {}
        }

        """
    }

    static func tests(name: String) -> String {
        """
        import Testing
        @testable import \(name)

        /// The kit as an app reaches it: through one root, for the life of the process.
        @MainActor
        struct \(name)Tests {
            @Test func theRootIsOneForTheProcess() {
                #expect(\(name)Root.shared === \(name)Root.shared)
            }
        }

        """
    }

    static let gitignore = """
        .DS_Store
        /.build
        /.swiftpm
        xcuserdata/

        """
}
