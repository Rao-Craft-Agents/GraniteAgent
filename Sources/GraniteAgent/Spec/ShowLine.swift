//  WHAT: A shows line: what a page draws, and from where.
//
//            items = feed.state.posts
//            selection = feed.state.selected
//            title = "Feed"
//            "Appearance/Theme" = config.state.appearance
//
//        A role or a quoted label, `=`, and a Swift expression. A label may name its section before a slash.

import Foundation

enum ShowLine {
    static func parse(_ line: String) throws -> Show {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let equals = LineSplit.firstTop(text, "="), text[text.index(after: equals)...].first != "=" else {
            throw GraniteError.line(line, "a shows line is `role = expression` or `\"Label\" = expression`")
        }
        let head = text[..<equals].trimmingCharacters(in: .whitespaces)
        let expression = text[text.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        guard !expression.isEmpty else { throw GraniteError.line(line, "`\(head) =` shows nothing") }
        if head.count >= 2, head.hasPrefix("\""), head.hasSuffix("\"") {
            let label = String(head.dropFirst().dropLast())
            let parts = label.split(separator: "/", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard let last = parts.last, !last.isEmpty else { throw GraniteError.line(line, "the label is empty") }
            return Show(key: .label(section: parts.count == 2 ? parts[0] : nil, text: last), expression: expression)
        }
        guard SwiftName.isMemberName(head) else {
            throw GraniteError.line(line, "`\(head)` is not a role (items, selection, title…) or a quoted label")
        }
        return Show(key: .role(head), expression: expression)
    }
}
