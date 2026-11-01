//  WHAT: A service added to the root that holds the relays (`AppRoot`, or a kit's `<Name>Root`): one
//        `@Relay(.silence)` line beside the others, so the service is hosted for the life of the process.
//  PIN:  IDEMPOTENT. A root that already holds a relay to the service is left as it is.

import Foundation

enum RootEditor {
    /// `root`'s text with a relay to `service` beside the others; nil when it holds one already or has no class.
    static func adding(_ service: String, as name: String, isPublic: Bool, to root: String) -> String? {
        if root.range(of: #"@Relay[^\n]*:\s*\#(service)\b"#, options: .regularExpression) != nil { return nil }
        var variable = name
        if root.range(of: #"\bvar \#(variable)\b"#, options: .regularExpression) != nil { variable = SwiftName.lowerFirst(service) }
        var lines = root.components(separatedBy: "\n")
        let line = "    @Relay(.silence) \(isPublic ? "public " : "")var \(SwiftName.member(variable)): \(service)"
        if let last = lines.lastIndex(where: { $0.contains("@Relay(") && $0.contains(" var ") }) {
            lines.insert(line, at: last + 1)
        } else if let shared = lines.firstIndex(where: { $0.contains("static let shared") }) {
            lines.insert(contentsOf: ["", line], at: shared + 1)
        } else if let declaration = lines.firstIndex(where: { $0.contains("final class ") && $0.hasSuffix("{") }) {
            lines.insert(line, at: declaration + 1)
        } else {
            return nil
        }
        return lines.joined(separator: "\n")
    }
}
