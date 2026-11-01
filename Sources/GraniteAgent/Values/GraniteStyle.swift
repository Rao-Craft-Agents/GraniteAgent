import Foundation

/// How the app moves between its destinations.
public enum GraniteStyle: String, Codable, Sendable, CaseIterable {
    /// A tab bar on a compact width, a sidebar beside the page on a regular one and on the Mac.
    case adaptive
    /// A tab bar on iPhone and iPad; a sidebar on the Mac.
    case tabs
    /// A sidebar everywhere; on iPhone it collapses into a list.
    case sidebar
    /// A sidebar, the destination and its detail pane, side by side.
    case split
}
