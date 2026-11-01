import Foundation

/// Something a page does, as an actions line says it: `refresh = try await feed.load(page: 1)`.
struct Action: Equatable, Sendable {
    var name: String
    var params: [Field]
    /// The button's words; the name's words when the line gave none.
    var title: String?
    /// The SF Symbol the button shows beside its words.
    var symbol: String?
    /// The Swift the action runs, one statement a line.
    var statements: [String]

    /// The button's words.
    var label: String { title ?? SwiftName.title(name) }

    /// Whether the action takes something away: its button is destructive.
    var isDestructive: Bool {
        let lower = name.lowercased()
        return ["delete", "remove", "reset", "clear", "signout", "logout", "block", "erase"].contains { lower.hasPrefix($0) }
    }
}
