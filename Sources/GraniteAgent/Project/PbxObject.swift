import Foundation

/// One object of an Xcode project file: its id, its fields, and where its text lies in the file (byte offsets, from
/// the start of its first line to the end of its last).
struct PbxObject: Sendable {
    let id: String
    let value: PlistValue
    let range: Range<Int>

    var isa: String { string("isa") ?? "" }

    func string(_ key: String) -> String? { value[key]?.string }

    /// The ids a list field holds, in order.
    func list(_ key: String) -> [String] { value[key]?.list?.compactMap(\.string) ?? [] }
}
