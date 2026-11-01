//  WHAT: A value of a type for a test to write and read back: a literal for Swift's own types, a type's `preview`
//        when the project has one, a list of one of them, nil for an optional with nothing to show.

import Foundation

enum Samples {
    /// A value of `type` that differs from its default, or nil when there is none to make.
    static func value(_ type: TypeRef, previews: Set<String>, enums: [String: [String]]) -> String? {
        switch type {
        case .optional(let wrapped):
            return value(wrapped, previews: previews, enums: enums) ?? "nil"
        case .array(let element):
            return value(element, previews: previews, enums: enums).map { "[\($0)]" }
        case .dictionary(let key, let value):
            guard let k = Self.value(key, previews: previews, enums: enums), let v = Self.value(value, previews: previews, enums: enums) else { return nil }
            return "[\(k): \(v)]"
        case .named(let name):
            switch name {
            case "String": return "\"sample\""
            case "Int", "Int64", "Int32", "Int16", "UInt", "UInt64", "UInt32": return "7"
            case "Double", "Float", "CGFloat": return "2.5"
            case "Bool": return "true"
            case "Date": return "Date(timeIntervalSince1970: 1_000)"
            case "URL": return "URL(fileURLWithPath: \"/sample\")"
            case "UUID": return "UUID(uuidString: \"00000000-0000-0000-0000-000000000001\")!"
            case "Data": return "Data([1, 2, 3])"
            default:
                if previews.contains(name) { return "\(name).preview" }
                if let cases = enums[name], let last = cases.last { return ".\(SwiftName.member(last))" }
                return nil
            }
        }
    }

    /// The value a field starts at when its line gives none: Swift's own types start empty, an optional at nil.
    static func zero(_ type: TypeRef) -> String? {
        switch type {
        case .optional: return nil
        case .array: return "[]"
        case .dictionary: return "[:]"
        case .named(let name):
            switch name {
            case "String": return "\"\""
            case "Int", "Int64", "Int32", "Int16", "UInt", "UInt64", "UInt32", "Double", "Float", "CGFloat": return "0"
            case "Bool": return "false"
            case "Data": return "Data()"
            default: return nil
            }
        }
    }
}
