//  WHAT: An actions line: what a page does when a person asks.
//
//            refresh = try await feed.load(page: 1)
//            vote(post Post, up Bool) = try await feed.vote(post: post, up: up)
//            compose "New Post" square.and.pencil = modals.sheet { Write() }
//
//        The name and its parameters (the field syntax), the button's words in quotes and its SF Symbol, both
//        optional, `=`, and the Swift it runs (statements split by `;`).

import Foundation

enum ActionLine {
    static func parse(_ line: String) throws -> Action {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let equals = LineSplit.firstTop(text, "=") else {
            throw GraniteError.line(line, "an action is `name = statement`, like `refresh = try await feed.load(page: 1)`")
        }
        var head = text[..<equals].trimmingCharacters(in: .whitespaces)
        let body = text[text.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        let statements = LineSplit.top(body, on: ";")
        guard !statements.isEmpty else { throw GraniteError.line(line, "the action runs nothing") }
        let name = String(head.prefix { $0.isLetter || $0.isNumber || $0 == "_" })
        guard SwiftName.isMemberName(name), !name.isEmpty else { throw GraniteError.line(line, "an action starts with its name in lowerCamelCase") }
        head = String(head.dropFirst(name.count)).trimmingCharacters(in: .whitespaces)
        var params: [Field] = []
        if head.hasPrefix("(") {
            guard let close = EventLine.closingParenthesis(head) else { throw GraniteError.line(line, "`(` after \(name) is never closed") }
            let inside = String(head[head.index(after: head.startIndex)..<close])
            params = try LineSplit.top(inside, on: ",").map { try FieldLine.parseField($0, in: line) }
            head = String(head[head.index(after: close)...]).trimmingCharacters(in: .whitespaces)
        }
        var title: String?
        if head.hasPrefix("\"") {
            guard let close = head.dropFirst().firstIndex(of: "\"") else { throw GraniteError.line(line, "the button's words are never closed") }
            title = String(head[head.index(after: head.startIndex)..<close])
            head = String(head[head.index(after: close)...]).trimmingCharacters(in: .whitespaces)
        }
        var symbol: String?
        if !head.isEmpty {
            guard head.range(of: #"^[a-z0-9]+(\.[a-z0-9]+)*$"#, options: .regularExpression) != nil else {
                throw GraniteError.line(line, "`\(head)` is not an SF Symbol name (like `square.and.pencil`)")
            }
            symbol = head
        }
        return Action(name: name, params: params, title: title, symbol: symbol, statements: statements)
    }
}
