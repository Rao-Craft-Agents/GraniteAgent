//  WHAT: What a type's fields say about how to show it: which reads as its title, which as a line under it, which
//        is a picture, a count or a date. What a row, a cell and a detail are made of when no one described them.

import Foundation

struct Describe {
    let index: ProjectIndex

    struct Pick {
        let name: String
        let type: String
        var optional: Bool { type.hasSuffix("?") }
        var bare: String { optional ? String(type.dropLast()) : type }
    }

    func fields(of type: String) -> [Pick] {
        (index.types[type]?.fields ?? []).map { Pick(name: $0.name, type: $0.type) }
    }

    func title(of type: String) -> Pick? {
        let strings = fields(of: type).filter { $0.bare == "String" && $0.name != "id" }
        return pick(strings, ["title", "name", "headline", "displayName", "label", "subject", "username", "handle", "text"]) ?? strings.first
    }

    func subtitle(of type: String, besides title: Pick?) -> Pick? {
        let strings = fields(of: type).filter { $0.bare == "String" && $0.name != "id" && $0.name != title?.name }
        return pick(strings, ["subtitle", "summary", "excerpt", "body", "description", "detail", "caption", "bio", "content", "message", "text", "author"])
    }

    func image(of type: String) -> Pick? {
        fields(of: type).first { field in
            field.bare == "URL" && ["image", "thumbnail", "avatar", "photo", "icon", "cover", "picture", "banner", "poster"].contains { field.name.lowercased().contains($0) }
        }
    }

    func metric(of type: String) -> Pick? {
        let numbers = fields(of: type).filter { ["Int", "Double"].contains($0.bare) && $0.name != "id" }
        return pick(numbers, ["score", "votes", "upvotes", "likes", "rating", "stars", "count", "comments", "minutes", "price"])
    }

    func date(of type: String) -> Pick? { fields(of: type).first { $0.bare == "Date" } }

    /// The SF Symbol a count reads with.
    static func symbol(for metric: String) -> String {
        let lower = metric.lowercased()
        if lower.contains("like") || lower.contains("heart") { return "heart" }
        if lower.contains("comment") || lower.contains("repl") { return "bubble.right" }
        if lower.contains("rating") || lower.contains("star") { return "star" }
        if lower.contains("minute") || lower.contains("time") || lower.contains("duration") { return "clock" }
        if lower.contains("price") || lower.contains("cost") { return "tag" }
        if lower.contains("count") { return "number" }
        return "arrow.up"
    }

    private func pick(_ fields: [Pick], _ names: [String]) -> Pick? {
        for name in names { if let field = fields.first(where: { $0.name.lowercased() == name.lowercased() }) { return field } }
        return nil
    }
}
