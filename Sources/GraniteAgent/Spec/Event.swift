import Foundation

/// One unit of a service's work, as an event line says it: `load(page Int) -> posts = API.posts(page: page)`.
struct Event: Equatable, Sendable {
    /// Where the work's result goes.
    enum Write: Equatable, Sendable {
        /// Nowhere: the work answers when it is done.
        case none
        /// Into the field, replacing what was there (`-> posts`).
        case replace(String)
        /// Onto the end of the field, a list (`+> posts`).
        case append(String)

        var field: String? {
            switch self {
            case .none: return nil
            case .replace(let field), .append(let field): return field
            }
        }
    }

    var verb: String
    var params: [Field]
    var write: Write
    /// The async throwing call that does the work; nil when the host's model writes the body.
    var expression: String?
    var doc: String?

    /// The reducer's type: `load` → `Load`.
    var typeName: String { SwiftName.upperFirst(verb) }
}
