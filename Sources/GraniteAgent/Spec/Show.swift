import Foundation

/// What a page shows, as a shows line says it: a role (`items = feed.state.posts`) or a labelled row of a form or
/// settings page (`"Appearance/Theme" = config.state.appearance`).
struct Show: Equatable, Sendable {
    enum Key: Equatable, Sendable {
        /// `items`, `selection`, `title`, `empty`, a view's parameter…
        case role(String)
        /// A row: its label, and the section it sits in when the line gave one.
        case label(section: String?, text: String)
    }

    var key: Key
    var expression: String

    /// Whether the expression is a string literal (`"Feed"`): text SwiftUI localizes.
    var isLiteral: Bool { expression.count >= 2 && expression.hasPrefix("\"") && expression.hasSuffix("\"") }

    /// The literal's text, unquoted.
    var literal: String? { isLiteral ? String(expression.dropFirst().dropLast()) : nil }

    var role: String? { if case .role(let role) = key { return role } else { return nil } }
}
