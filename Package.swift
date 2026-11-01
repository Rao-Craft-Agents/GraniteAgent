// swift-tools-version:6.0
// GraniteAgent: everything Granite-specific an iOS + macOS app needs — the project, its services, its pages, its
// navigation and its modals — written from compact lines, as a Granite agent package. An app that links it finds the
// `granite` agent through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "GraniteAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GraniteAgent", targets: ["GraniteAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "GraniteAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "GraniteAgentTests",
            dependencies: ["GraniteAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
