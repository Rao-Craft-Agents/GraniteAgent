//  WHAT: A Swift type as a line wrote it: a name, an array, a dictionary, optional or not. ModelsAgent's, so a type
//        reads the same in every agent of the family.

import Foundation

indirect enum TypeRef: Equatable, Sendable, CustomStringConvertible {
    case named(String)
    case array(TypeRef)
    case dictionary(TypeRef, TypeRef)
    case optional(TypeRef)

    var description: String {
        switch self {
        case .named(let name): return name
        case .array(let element): return "[\(element)]"
        case .dictionary(let key, let value): return "[\(key): \(value)]"
        case .optional(let wrapped):
            if case .named = wrapped { return "\(wrapped)?" }
            if case .array = wrapped { return "\(wrapped)?" }
            if case .dictionary = wrapped { return "\(wrapped)?" }
            return "(\(wrapped))?"
        }
    }

    var isOptional: Bool { if case .optional = self { return true } else { return false } }

    var unwrapped: TypeRef { if case .optional(let wrapped) = self { return wrapped } else { return self } }

    /// The element of an array (optional or not); nil for anything else.
    var element: TypeRef? {
        if case .array(let element) = unwrapped { return element }
        return nil
    }

    /// Every type name it mentions.
    var names: [String] {
        switch self {
        case .named(let name): return [name]
        case .array(let element): return element.names
        case .dictionary(let key, let value): return key.names + value.names
        case .optional(let wrapped): return wrapped.names
        }
    }
}
