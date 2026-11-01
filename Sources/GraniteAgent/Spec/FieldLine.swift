//  WHAT: ModelsAgent's field syntax, the one form every agent of the family takes a field in:
//
//            posts [Post] = [], selected String? "the post on screen", score: Int = 0
//
//        A name and a type (`title String` or `title: String`), `?` for optional, `= value` for a default, `@key` for
//        a JSON key and a trailing quoted doc. `string`, `int`, `bool`, `url` and `date` read as the Swift types.
//  PIN:  A LINE THAT IS NOT UNDERSTOOD IS REFUSED WITH THE REASON. A guess would write state the person did not ask
//        for, and the turn would build it; the model can only fix a line it is told about.

import Foundation

enum FieldLine {
    /// `title String = "x" @name "the headline"`, or `title: String`.
    static func parseField(_ piece: String, in line: String) throws -> Field {
        var text = piece.trimmingCharacters(in: .whitespaces)
        var doc: String?
        if text.hasSuffix("\""), let open = lastQuotedStart(text) {
            let candidate = String(text[open...])
            // A trailing quoted string is a doc only when it does not belong to a default (`= "x"`).
            let before = text[..<open].trimmingCharacters(in: .whitespaces)
            if !before.hasSuffix("=") {
                doc = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                text = before
            }
        }
        var key: String?
        if let at = lastTopAt(text) {
            key = String(text[text.index(after: at)...]).trimmingCharacters(in: .whitespaces)
            text = String(text[..<at]).trimmingCharacters(in: .whitespaces)
            guard let found = key, !found.isEmpty, !found.contains(" ") else { throw GraniteError.line(line, "`@` in `\(piece)` names no key") }
        }
        var defaultValue: String?
        if let equals = LineSplit.firstTop(text, "=") {
            defaultValue = String(text[text.index(after: equals)...]).trimmingCharacters(in: .whitespaces)
            text = String(text[..<equals]).trimmingCharacters(in: .whitespaces)
            if defaultValue?.isEmpty ?? true { throw GraniteError.line(line, "`\(piece)` has `=` and no value") }
        }
        let name: String, typeText: String
        if let colon = LineSplit.firstTop(text, ":") {
            name = String(text[..<colon]).trimmingCharacters(in: .whitespaces)
            typeText = String(text[text.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        } else if let space = text.firstIndex(of: " ") {
            name = String(text[..<space])
            typeText = String(text[space...]).trimmingCharacters(in: .whitespaces)
        } else {
            throw GraniteError.line(line, "`\(piece)` needs a name and a type, like `title String`")
        }
        let bare = name.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
        guard SwiftName.isMemberName(bare) else { throw GraniteError.line(line, "`\(name)` is not a field name (lowerCamelCase)") }
        let type = try parseType(typeText, in: line)
        return Field(name: bare, type: type, defaultValue: defaultValue, key: key, doc: doc)
    }

    /// `String`, `User?`, `[String]`, `[String: Int]`, `[Post]?`, `Swift.Int`.
    static func parseType(_ text: String, in line: String) throws -> TypeRef {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw GraniteError.line(line, "a field has no type") }
        if trimmed.hasSuffix("?") { return .optional(try parseType(String(trimmed.dropLast()), in: line)) }
        if trimmed.hasPrefix("("), trimmed.hasSuffix(")") { return try parseType(String(trimmed.dropFirst().dropLast()), in: line) }
        if trimmed.hasPrefix("["), trimmed.hasSuffix("]") {
            let inside = String(trimmed.dropFirst().dropLast())
            if let colon = LineSplit.firstTop(inside, ":") {
                return .dictionary(try parseType(String(inside[..<colon]), in: line), try parseType(String(inside[inside.index(after: colon)...]), in: line))
            }
            return .array(try parseType(inside, in: line))
        }
        let aliases = ["string": "String", "int": "Int", "integer": "Int", "double": "Double", "float": "Double", "number": "Double",
                       "bool": "Bool", "boolean": "Bool", "date": "Date", "url": "URL", "uuid": "UUID", "data": "Data"]
        let name = aliases[trimmed.lowercased()] ?? trimmed
        guard name.split(separator: ".").allSatisfy({ SwiftName.isTypeName(String($0)) }) else {
            throw GraniteError.line(line, "`\(trimmed)` is not a type")
        }
        return .named(name)
    }

    /// Where the last quoted string in `text` begins, when `text` ends with its closing quote.
    static func lastQuotedStart(_ text: String) -> String.Index? {
        guard text.hasSuffix("\""), text.count >= 2 else { return nil }
        var index = text.index(before: text.index(before: text.endIndex))
        while true {
            if text[index] == "\"" { return index }
            if index == text.startIndex { return nil }
            index = text.index(before: index)
        }
    }

    /// The last `@` outside brackets and quotes.
    private static func lastTopAt(_ text: String) -> String.Index? {
        var found: String.Index?, depth = 0, quoted = false
        var index = text.startIndex
        while index < text.endIndex {
            let c = text[index]
            if c == "\"" { quoted.toggle() } else if !quoted {
                if "[({".contains(c) { depth += 1 } else if "])}".contains(c) { depth = max(0, depth - 1) }
                else if c == "@" && depth == 0 { found = index }
            }
            index = text.index(after: index)
        }
        return found
    }
}
