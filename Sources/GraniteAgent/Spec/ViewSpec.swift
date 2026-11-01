import Foundation

/// A subview of a page, as a views line says it: `row(post Post, vote (Bool) -> Void) "title, author and score"`.
struct ViewSpec: Equatable, Sendable {
    struct Param: Equatable, Sendable {
        var name: String
        /// The type as written: `Post`, `[String]`, `(Bool) -> Void`.
        var type: String
        /// A closure: the view calls it, and hides its control when the page gives none.
        var isClosure: Bool { type.contains("->") }
    }

    var role: String
    var params: [Param]
    /// What the view shows, in a person's words: what the host's model writes the body from.
    var description: String?

    /// `row` → `Row`.
    var roleName: String { SwiftName.upperFirst(role) }

    var values: [Param] { params.filter { !$0.isClosure } }
    var closures: [Param] { params.filter(\.isClosure) }
}
