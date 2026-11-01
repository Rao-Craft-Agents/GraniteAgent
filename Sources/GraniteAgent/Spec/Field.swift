import Foundation

/// One field as a line says it: `posts [Post] = []`, `selected String? "the post on screen"`.
struct Field: Equatable, Sendable {
    var name: String
    var type: TypeRef
    var defaultValue: String?
    /// The key it is read from and written to in JSON, when not its name (`@post_id`).
    var key: String?
    var doc: String?
}
