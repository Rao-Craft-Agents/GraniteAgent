import Foundation

/// A remote package an app or a kit depends on, pinned: `https://github.com/kean/Nuke@<revision> Nuke NukeUI`.
struct PackageDependency: Equatable, Sendable {
    enum Requirement: Equatable, Sendable {
        /// A commit: 40 hex digits.
        case revision(String)
        /// A release: `12.8.0`.
        case exact(String)
    }

    var url: String
    var requirement: Requirement
    var products: [String]

    /// The package's name as its URL says it: `Nuke`.
    var identity: String {
        let last = url.split(separator: "/").last.map(String.init) ?? url
        return last.hasSuffix(".git") ? String(last.dropLast(4)) : last
    }
}
