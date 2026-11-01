import Foundation

/// What a call will write: whole files, and files it edits written whole again, staged and landed together.
struct Plan {
    /// Where a Swift file belongs in an Xcode project: the app's targets, the unit tests', or neither (a package's).
    enum Role { case app, tests, other }

    var files: [(url: URL, text: String, role: Role)] = []
    var types: [String] = []
    var notes: [String] = []

    /// Adds a file, or replaces what an earlier step planned for the same place.
    mutating func write(_ url: URL, _ text: String, role: Role = .app) {
        if let index = files.firstIndex(where: { $0.url.path == url.path }) {
            files[index] = (url, text, files[index].role)
        } else {
            files.append((url, text, role))
        }
    }

    func text(at url: URL) -> String? { files.first { $0.url.path == url.path }?.text }
}
