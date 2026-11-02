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

    /// Why `relay` cannot be held, when the project has no such service. A type it has that is not a service (a
    /// client, a model) is called in an event's work, not relayed: told "make it first", a model made an empty
    /// `HearthClientService` to hold `client: HearthClient` (Hearth, 2026-11-01).
    static func missing(_ line: String, relay: Relay, declared: Set<String>) -> String {
        let text = line.trimmingCharacters(in: .whitespaces)
        let named = (text.firstIndex(of: ":").map { String(text[text.index(after: $0)...]) } ?? text.split(separator: " ").last.map(String.init) ?? text)
            .trimmingCharacters(in: .whitespaces)
        if named != relay.type, declared.contains(named) {
            return "`\(named)` is not a service, so it is not relayed: an event's work calls it (`load(page Int) -> items = \(named)…`), "
                + "and `relays` name only the app's services (`feed: FeedService`)"
        }
        return "`\(relay.type)` is not in the project: make it first (`make: service`, `type: \(SwiftName.service(relay.type).base)`)"
    }
}
