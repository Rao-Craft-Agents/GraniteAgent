//  WHAT: A destinations line: one place the app goes, as the sidebar and the tab bar show it.
//
//            feed: Feed "Feed" house
//            search: Search(scope: .all) "Search" magnifyingglass
//            inbox: Inbox "Inbox" tray | Message
//
//        The case, the view (a component, with arguments when it takes any), the title in quotes, its SF Symbol, and
//        after a bar the view the detail pane shows beside it in the split style.

import Foundation

enum DestinationLine {
    static func parse(_ line: String) throws -> Destination {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let colon = text.firstIndex(of: ":") else {
            throw GraniteError.line(line, "a destination is `name: View \"Title\" symbol`, like `feed: Feed \"Feed\" house`")
        }
        let name = text[..<colon].trimmingCharacters(in: .whitespaces)
        guard SwiftName.isMemberName(name) else { throw GraniteError.line(line, "`\(name)` is not a case name (lowerCamelCase)") }
        var rest = text[text.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        var detail: String?
        if let bar = LineSplit.firstTop(rest, "|") {
            detail = rest[rest.index(after: bar)...].trimmingCharacters(in: .whitespaces)
            rest = rest[..<bar].trimmingCharacters(in: .whitespaces)
        }
        guard let quote = rest.firstIndex(of: "\""), let end = rest[rest.index(after: quote)...].firstIndex(of: "\"") else {
            throw GraniteError.line(line, "the destination's title goes in quotes, like `\"Feed\"`")
        }
        let view = rest[..<quote].trimmingCharacters(in: .whitespaces)
        let title = String(rest[rest.index(after: quote)..<end])
        let symbol = rest[rest.index(after: end)...].trimmingCharacters(in: .whitespaces)
        let (viewText, viewType) = try viewCall(view, in: line)
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { throw GraniteError.line(line, "the title is empty") }
        guard symbol.range(of: #"^[a-z0-9]+(\.[a-z0-9]+)*$"#, options: .regularExpression) != nil else {
            throw GraniteError.line(line, "after the title comes the destination's SF Symbol, like `house` or `gearshape`")
        }
        var detailText: String?, detailType: String?
        if let detail { (detailText, detailType) = try viewCall(detail, in: line) }
        return Destination(name: name, view: viewText, viewType: viewType, title: title, symbol: symbol, detail: detailText, detailType: detailType)
    }

    /// `Feed` → (`Feed()`, `Feed`); `Feed(kind: .all)` stays as written.
    private static func viewCall(_ text: String, in line: String) throws -> (String, String) {
        let type = String(text.prefix { $0.isLetter || $0.isNumber || $0 == "_" })
        guard SwiftName.isTypeName(type) else { throw GraniteError.line(line, "`\(text)` is not a view (a type in UpperCamelCase)") }
        let rest = text.dropFirst(type.count).trimmingCharacters(in: .whitespaces)
        if rest.isEmpty { return ("\(type)()", type) }
        guard rest.hasPrefix("("), let close = EventLine.closingParenthesis(rest), rest.index(after: close) == rest.endIndex else {
            throw GraniteError.line(line, "`\(text)` is not a view call like `Feed` or `Feed(kind: .all)`")
        }
        return ("\(type)\(rest)", type)
    }
}
