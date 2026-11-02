//  WHAT: A service's event line: one unit of work, what it is given, where its result goes and what does it.
//
//            load(page Int) -> posts = LemmyAPI.posts(page: page) "loads one page"
//            more(page Int) +> posts = LemmyAPI.posts(page: page)
//            vote(post Post, up Bool) = LemmyAPI.vote(post.id, up: up)
//            refresh() -> posts "the first page again, newest first"
//
//        The verb and its parameters (the field syntax); `-> field` writes the result into the state, `+> field`
//        appends it to a list; `= expression` is the call that does the work (the agent adds `try await`); with no
//        expression the host's model writes the body. A trailing quoted string is the doc.
//  PIN:  NAMES THE REDUCER USES ARE NOT A PARAMETER'S. The effect binds `ticket`, `service` and `value` itself; a
//        parameter by one of those names would shadow it, so the line is refused rather than renamed.

import Foundation

enum EventLine {
    /// Verbs a service already answers to.
    static let reservedVerbs: Set<String> = ["set", "binding", "center", "state", "reply", "tickets", "lane", "clear", "restore", "preload"]
    /// Names the reducer's effect binds for itself.
    static let reservedParameters: Set<String> = ["ticket", "service", "value", "error", "meta", "state", "work"]

    static func parse(_ line: String) throws -> Event {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw GraniteError.line(line, "it is empty") }
        var doc: String?
        if text.hasSuffix("\""), let open = FieldLine.lastQuotedStart(text) {
            let before = text[..<open].trimmingCharacters(in: .whitespaces)
            if !before.isEmpty, !before.hasSuffix("="), !before.hasSuffix("("), !before.hasSuffix(","), !before.hasSuffix("+") {
                doc = String(text[open...]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                text = before
            }
        }
        let verb = String(text.prefix { $0.isLetter || $0.isNumber || $0 == "_" })
        guard SwiftName.isMemberName(verb), !verb.isEmpty else {
            throw GraniteError.line(line, "an event starts with its verb in lowerCamelCase, like `load(page Int) -> posts`")
        }
        guard !reservedVerbs.contains(verb) else {
            throw GraniteError.line(line, "`\(verb)` is the service's own; name the work something else")
        }
        var rest = text.dropFirst(verb.count).trimmingCharacters(in: .whitespaces)
        var params: [Field] = []
        if rest.hasPrefix("(") {
            guard let close = closingParenthesis(rest) else { throw GraniteError.line(line, "`(` after \(verb) is never closed") }
            let inside = String(rest[rest.index(after: rest.startIndex)..<close])
            // `_ body NewPost` is a Swift habit: the label is dropped, a parameter is its name and type (Margin, 2026-11-01).
            params = try LineSplit.top(inside, on: ",").map { piece in
                var text = piece.trimmingCharacters(in: .whitespaces)
                if text.hasPrefix("_ ") { text = String(text.dropFirst(2)) }
                return try FieldLine.parseField(text, in: line)
            }
            rest = String(rest[rest.index(after: close)...]).trimmingCharacters(in: .whitespaces)
        }
        var seen: Set<String> = []
        for param in params {
            guard seen.insert(param.name).inserted else { throw GraniteError.line(line, "the parameter `\(param.name)` is named twice") }
            guard !reservedParameters.contains(param.name) else {
                throw GraniteError.line(line, "a parameter may not be named `\(param.name)`: the work's reducer uses that name itself")
            }
        }
        var write = Event.Write.none
        if rest.hasPrefix("=>") || rest.hasPrefix("<-") {
            throw GraniteError.line(line, "`\(rest.prefix(2))` is not an arrow, not `=> posts`: `-> field` writes the result into a field, `+> field` appends it")
        }
        if rest.hasPrefix("->") || rest.hasPrefix("+>") {

            let appends = rest.hasPrefix("+>")
            rest = String(rest.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            let field = String(rest.prefix { $0.isLetter || $0.isNumber || $0 == "_" })
            guard SwiftName.isMemberName(field), !field.isEmpty else {
                throw GraniteError.line(line, "`\(appends ? "+>" : "->")` names the state field the result goes into, like `-> posts`")
            }
            write = appends ? .append(field) : .replace(field)
            rest = String(rest.dropFirst(field.count)).trimmingCharacters(in: .whitespaces)
        }
        var expression: String?
        if rest.hasPrefix("=") {
            var call = String(rest.dropFirst()).trimmingCharacters(in: .whitespaces)
            for prefix in ["try await ", "await try ", "try ", "await "] where call.hasPrefix(prefix) {
                call = String(call.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
            guard !call.isEmpty else { throw GraniteError.line(line, "`=` gives no expression") }
            expression = call
        } else if !rest.isEmpty {
            throw GraniteError.line(line, "after \(verb)'s parameters comes `-> field`, `+> field` or `= expression`, not `\(rest)`")
        }
        return Event(verb: verb, params: params, write: write, expression: expression, doc: doc)
    }

    /// The `)` that closes the `(` `text` starts with, outside quotes and nested brackets.
    static func closingParenthesis(_ text: String) -> String.Index? {
        var depth = 0, quoted = false, escaped = false
        var index = text.startIndex
        while index < text.endIndex {
            let c = text[index]
            if quoted {
                if escaped { escaped = false } else if c == "\\" { escaped = true } else if c == "\"" { quoted = false }
            } else if c == "\"" {
                quoted = true
            } else if "([{".contains(c) {
                depth += 1
            } else if ")]}".contains(c) {
                depth -= 1
                if depth == 0 && c == ")" { return index }
            }
            index = text.index(after: index)
        }
        return nil
    }
}
