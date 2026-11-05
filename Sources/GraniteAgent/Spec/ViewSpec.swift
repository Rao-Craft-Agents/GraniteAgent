import Foundation

/// A subview of a page, as a views line says it: `row(post Post, vote (Bool) -> Void) "title, author and score"`.
struct ViewSpec: Equatable, Sendable {
    struct Param: Equatable, Sendable {
        var name: String
        /// The type as written: `Post`, `[String]`, `(Bool) -> Void`.
        var type: String
        /// A closure: an action the view sends up with `bubble`, which the page routes to the action of its name.
        var isClosure: Bool { type.contains("->") }
    }

    var role: String
    var params: [Param]
    /// What the view shows, in a person's words: what the host's model writes the body from.
    var description: String?

    /// `row` → `Row`.
    /// The role as it names the view: `row` is `Row` (`FeedRowView`); a role already ending in View loses it, so
    /// `feedView` is `Feed` and the view `FeedFeedView`, never `FeedFeedViewView`.
    var roleName: String {
        let name = SwiftName.upperFirst(role)
        return name.count > 4 && name.hasSuffix("View") ? String(name.dropLast(4)) : name
    }

    var values: [Param] { params.filter { !$0.isClosure } }
    var closures: [Param] { params.filter(\.isClosure) }
}

/// How a view's actions travel to its page: a `GraniteBubble.Name` per closure, declared beside the view, a
/// function the view's body calls to send it, and the route the page puts where it draws the view.
enum ViewBubble {
    /// `RecipeDetailHeaderView`'s `rate` → `recipeDetailHeaderRate`: prefixed by the view, so no two views'
    /// names collide in the module.
    static func constant(_ viewType: String, _ closure: ViewSpec.Param) -> String {
        let base = viewType.count > 4 && viewType.hasSuffix("View") ? String(viewType.dropLast(4)) : viewType
        return SwiftName.lowerFirst(base) + SwiftName.upperFirst(closure.name)
    }

    /// The name as sent: `"RecipeDetailHeaderView.rate"`.
    static func rawValue(_ viewType: String, _ closure: ViewSpec.Param) -> String { "\(viewType).\(closure.name)" }

    /// What the closure carries: nothing, one type, or a tuple of them.
    static func payload(_ closure: ViewSpec.Param) -> String? {
        let inputs = ComponentSpec.closureInputs(closure.type)
        switch inputs.count {
        case 0: return nil
        case 1: return inputs[0]
        default: return "(" + inputs.joined(separator: ", ") + ")"
        }
    }

    /// The function the view's body calls: `func rate(_ stars: Int)`, as a signature (`withBody: false`) or whole.
    static func function(_ viewType: String, _ closure: ViewSpec.Param, withBody: Bool = true) -> String {
        let inputs = ComponentSpec.closureInputs(closure.type)
        let names = inputs.count == 1 ? ["value"] : inputs.indices.map { "value\($0 + 1)" }
        let parameters = zip(names, inputs).map { "_ \($0): \($1)" }.joined(separator: ", ")
        let signature = "func \(SwiftName.member(closure.name))(\(parameters))"
        guard withBody else { return signature }
        let constant = constant(viewType, closure)
        let sent: String
        switch inputs.count {
        case 0: sent = "bubble(.\(constant))"
        case 1: sent = "bubble(.\(constant), value)"
        default: sent = "bubble(.\(constant), (" + names.joined(separator: ", ") + "))"
        }
        return "private \(signature) { \(sent) }"
    }
}
