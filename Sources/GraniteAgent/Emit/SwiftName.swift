//  WHAT: What Swift accepts as a name, and how a name is said: keywords escaped, words split for a title, a type's
//        name turned into a variable's, a service's name made whole (`Config` is `ConfigService`).

import Foundation

enum SwiftName {
    /// Words Swift reserves: a member by one of these names is written in backticks. Contextual words (`open`,
    /// `some`, `any`) are not among them: `func open()` is a name like any other.
    static let keywords: Set<String> = ["associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init",
                                        "inout", "internal", "let", "operator", "private", "precedencegroup", "protocol", "public",
                                        "rethrows", "static", "struct", "subscript", "typealias", "var", "break", "case", "catch", "continue",
                                        "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
                                        "switch", "where", "while", "as", "Any", "false", "is", "nil", "self", "Self", "super", "throws", "true",
                                        "try"]

    static func isTypeName(_ text: String) -> Bool {
        text.range(of: #"^[A-Z][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    static func isMemberName(_ text: String) -> Bool {
        text.range(of: #"^[a-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    /// A member name as code writes it: a keyword in backticks.
    static func member(_ name: String) -> String { keywords.contains(name) ? "`\(name)`" : name }

    /// `displayName` → `display name`; `postID` → `post id`.
    static func words(_ name: String) -> String {
        var out = "", previous: Character?
        for character in name {
            if character == "_" { out.append(" ") }
            else if character.isUppercase, let p = previous, p.isLowercase || p.isNumber { out.append(" "); out.append(Character(character.lowercased())) }
            else { out.append(Character(character.lowercased())) }
            previous = character
        }
        return out
    }

    /// `displayName` → `display_name`.
    static func snake(_ name: String) -> String { words(name).replacingOccurrences(of: " ", with: "_") }

    /// `markAllRead` → `Mark All Read`: a button's or a heading's words.
    static func title(_ name: String) -> String {
        words(name).split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    /// `FeedService` → `feedService`; `URLSession` → `urlSession`.
    static func lowerFirst(_ name: String) -> String {
        let leadingCaps = name.prefix { $0.isUppercase }
        if leadingCaps.count > 1 && leadingCaps.count < name.count {
            return leadingCaps.dropLast().lowercased() + name.dropFirst(leadingCaps.count - 1)
        }
        if leadingCaps.count == name.count { return name.lowercased() }
        return name.prefix(1).lowercased() + name.dropFirst()
    }

    /// `load` → `Load`.
    static func upperFirst(_ name: String) -> String { name.prefix(1).uppercased() + name.dropFirst() }

    /// A doc line as a sentence: capitalized, ending with a period.
    static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return trimmed }
        let capped = first.uppercased() + trimmed.dropFirst()
        return capped.hasSuffix(".") || capped.hasSuffix("?") || capped.hasSuffix("!") ? capped : capped + "."
    }

    /// A service's name made whole: `Config` and `ConfigService` are both `ConfigService`, and its base is `Config`.
    static func service(_ text: String) -> (type: String, base: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("Service"), trimmed.count > "Service".count { return (trimmed, String(trimmed.dropLast("Service".count))) }
        return (trimmed + "Service", trimmed)
    }

    /// The variable a relay to `service` is held in: `FeedService` → `feed`.
    static func relayName(_ service: String) -> String { lowerFirst(Self.service(service).base) }

    /// A string as a Swift string literal's contents: quotes and backslashes escaped.
    static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
