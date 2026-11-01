import Foundation

/// A value in an Xcode project file (the old OpenStep property list): a string, a list or a dictionary, in the order
/// the file wrote it.
indirect enum PlistValue: Equatable, Sendable {
    case string(String)
    case list([PlistValue])
    case dict([Entry])

    struct Entry: Equatable, Sendable {
        var key: String
        var value: PlistValue
    }

    var string: String? { if case .string(let value) = self { return value } else { return nil } }

    var list: [PlistValue]? { if case .list(let values) = self { return values } else { return nil } }

    var entries: [Entry]? { if case .dict(let entries) = self { return entries } else { return nil } }

    /// The value under `key`, when this is a dictionary that has one.
    subscript(key: String) -> PlistValue? { entries?.first { $0.key == key }?.value }
}
