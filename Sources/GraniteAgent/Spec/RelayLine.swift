//  WHAT: A relay line: `feed: FeedService`, `FeedService`, or `Feed`. The service's name is made whole (`Feed` is
//        `FeedService`) and the variable, when left out, is its base in lowerCamelCase (`feed`).

import Foundation

enum RelayLine {
    static func parse(_ line: String) throws -> Relay {
        let text = line.trimmingCharacters(in: .whitespaces)
        var name: String?
        var typeText = text
        if let colon = text.firstIndex(of: ":") {
            name = text[..<colon].trimmingCharacters(in: .whitespaces)
            typeText = text[text.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        } else if let space = text.firstIndex(of: " ") {
            name = text[..<space].trimmingCharacters(in: .whitespaces)
            typeText = text[space...].trimmingCharacters(in: .whitespaces)
        }
        guard SwiftName.isTypeName(typeText) else {
            throw GraniteError.line(line, "a relay is `name: Service` or `Service`, and `\(typeText)` is not a type name")
        }
        let type = SwiftName.service(typeText).type
        let variable = name ?? SwiftName.relayName(type)
        guard SwiftName.isMemberName(variable) else { throw GraniteError.line(line, "`\(variable)` is not a variable name (lowerCamelCase)") }
        return Relay(name: variable, type: type)
    }
}
