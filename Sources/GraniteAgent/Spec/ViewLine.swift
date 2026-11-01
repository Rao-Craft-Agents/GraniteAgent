//  WHAT: A views line: one subview of a page, what it takes and what it shows.
//
//            row(post Post, vote (Bool) -> Void) "title, author and score, with a vote control"
//            header(count Int)
//
//        Its role (the file is `<Page>.<Role>View.swift`, the type `<Page><Role>View`), its values and closures, and
//        in quotes what it shows. With a description the host's model writes the body; without one, the body is
//        made from the value's fields.

import Foundation

enum ViewLine {
    static func parse(_ line: String) throws -> ViewSpec {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var description: String?
        if text.hasSuffix("\""), let open = FieldLine.lastQuotedStart(text) {
            description = String(text[open...]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            text = text[..<open].trimmingCharacters(in: .whitespaces)
        }
        let role = String(text.prefix { $0.isLetter || $0.isNumber || $0 == "_" })
        guard SwiftName.isMemberName(role), !role.isEmpty else {
            throw GraniteError.line(line, "a view starts with its role in lowerCamelCase, like `row(post Post)`")
        }
        var rest = String(text.dropFirst(role.count)).trimmingCharacters(in: .whitespaces)
        var params: [ViewSpec.Param] = []
        if rest.hasPrefix("(") {
            guard let close = EventLine.closingParenthesis(rest) else { throw GraniteError.line(line, "`(` after \(role) is never closed") }
            let inside = String(rest[rest.index(after: rest.startIndex)..<close])
            for piece in LineSplit.top(inside, on: ",") {
                let trimmed = piece.trimmingCharacters(in: .whitespaces)
                let name: String, type: String
                if let colon = LineSplit.firstTop(trimmed, ":"), trimmed[..<colon].allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) {
                    name = String(trimmed[..<colon]); type = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                } else if let space = trimmed.firstIndex(of: " ") {
                    name = String(trimmed[..<space]); type = trimmed[space...].trimmingCharacters(in: .whitespaces)
                } else {
                    throw GraniteError.line(line, "`\(trimmed)` needs a name and a type, like `post Post` or `vote (Bool) -> Void`")
                }
                guard SwiftName.isMemberName(name) else { throw GraniteError.line(line, "`\(name)` is not a parameter name (lowerCamelCase)") }
                if !type.contains("->") { _ = try FieldLine.parseType(type, in: line) }
                guard !params.contains(where: { $0.name == name }) else { throw GraniteError.line(line, "`\(name)` is named twice") }
                params.append(.init(name: name, type: type))
            }
            rest = String(rest[rest.index(after: close)...]).trimmingCharacters(in: .whitespaces)
        }
        guard rest.isEmpty else { throw GraniteError.line(line, "`\(rest)` after the view's parameters is not understood") }
        return ViewSpec(role: role, params: params, description: description)
    }
}
