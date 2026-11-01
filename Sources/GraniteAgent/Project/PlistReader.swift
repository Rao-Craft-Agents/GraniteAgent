//  WHAT: A reader of the old OpenStep property lists Xcode writes its project files in: dictionaries, lists, quoted
//        and bare strings, comments skipped. Each object of the `objects` dictionary keeps where its text lies, so
//        an edit can change that text and nothing else.

import Foundation

struct PlistReader {
    struct Document {
        let root: PlistValue
        let objects: [PbxObject]
    }

    private let bytes: [UInt8]
    private var index = 0
    private var objects: [PbxObject] = []

    init(_ bytes: [UInt8]) { self.bytes = bytes }

    mutating func document() throws -> Document {
        skip()
        guard index < bytes.count, bytes[index] == UInt8(ascii: "{") else { throw failure("the project file does not start with `{`") }
        let root = try dictionary(depth: 0, record: false)
        return Document(root: .dict(root), objects: objects)
    }

    private mutating func value(depth: Int) throws -> PlistValue {
        skip()
        guard index < bytes.count else { throw failure("the project file ends inside a value") }
        switch bytes[index] {
        case UInt8(ascii: "{"): return .dict(try dictionary(depth: depth, record: false))
        case UInt8(ascii: "("): return .list(try list(depth: depth))
        default: return .string(try string())
        }
    }

    private mutating func dictionary(depth: Int, record: Bool) throws -> [PlistValue.Entry] {
        index += 1
        var entries: [PlistValue.Entry] = []
        while true {
            skip()
            guard index < bytes.count else { throw failure("a dictionary in the project file is never closed") }
            if bytes[index] == UInt8(ascii: "}") { index += 1; return entries }
            let keyStart = index
            let key = try string()
            skip()
            try expect("=")
            let value: PlistValue
            if depth == 0 && key == "objects" {
                skip()
                guard index < bytes.count, bytes[index] == UInt8(ascii: "{") else { throw failure("`objects` is not a dictionary") }
                value = .dict(try dictionary(depth: depth + 1, record: true))
            } else {
                value = try self.value(depth: depth + 1)
            }
            skip()
            try expect(";")
            if record {
                var end = index
                if end < bytes.count, bytes[end] == UInt8(ascii: "\n") { end += 1 }
                objects.append(PbxObject(id: key, value: value, range: lineStart(keyStart)..<end))
            }
            entries.append(.init(key: key, value: value))
        }
    }

    private mutating func list(depth: Int) throws -> [PlistValue] {
        index += 1
        var values: [PlistValue] = []
        while true {
            skip()
            guard index < bytes.count else { throw failure("a list in the project file is never closed") }
            if bytes[index] == UInt8(ascii: ")") { index += 1; return values }
            values.append(try value(depth: depth + 1))
            skip()
            if index < bytes.count, bytes[index] == UInt8(ascii: ",") { index += 1 }
        }
    }

    private mutating func string() throws -> String {
        guard index < bytes.count else { throw failure("the project file ends where a string should be") }
        if bytes[index] == UInt8(ascii: "\"") {
            index += 1
            var out: [UInt8] = []
            while index < bytes.count, bytes[index] != UInt8(ascii: "\"") {
                if bytes[index] == UInt8(ascii: "\\"), index + 1 < bytes.count {
                    index += 1
                    switch bytes[index] {
                    case UInt8(ascii: "n"): out.append(UInt8(ascii: "\n"))
                    case UInt8(ascii: "t"): out.append(UInt8(ascii: "\t"))
                    default: out.append(bytes[index])
                    }
                } else {
                    out.append(bytes[index])
                }
                index += 1
            }
            guard index < bytes.count else { throw failure("a quoted string in the project file is never closed") }
            index += 1
            return String(decoding: out, as: UTF8.self)
        }
        let start = index
        let stops: Set<UInt8> = Set("{}()=;,\" \t\n\r".utf8)
        while index < bytes.count, !stops.contains(bytes[index]) { index += 1 }
        guard index > start else { throw failure("the project file has `\(Character(UnicodeScalar(bytes[index])))` where a string should be") }
        return String(decoding: bytes[start..<index], as: UTF8.self)
    }

    private mutating func skip() {
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
                index += 1
            } else if byte == UInt8(ascii: "/"), index + 1 < bytes.count, bytes[index + 1] == UInt8(ascii: "*") {
                index += 2
                while index + 1 < bytes.count, !(bytes[index] == UInt8(ascii: "*") && bytes[index + 1] == UInt8(ascii: "/")) { index += 1 }
                index = min(bytes.count, index + 2)
            } else if byte == UInt8(ascii: "/"), index + 1 < bytes.count, bytes[index + 1] == UInt8(ascii: "/") {
                while index < bytes.count, bytes[index] != 0x0A { index += 1 }
            } else {
                return
            }
        }
    }

    private mutating func expect(_ character: Character) throws {
        guard index < bytes.count, bytes[index] == character.asciiValue else {
            throw failure("the project file has no `\(character)` where one belongs")
        }
        index += 1
    }

    private func lineStart(_ position: Int) -> Int {
        var start = position
        while start > 0, bytes[start - 1] != 0x0A { start -= 1 }
        return start
    }

    private func failure(_ reason: String) -> GraniteError {
        var line = 1
        for byte in bytes[..<min(index, bytes.count)] where byte == 0x0A { line += 1 }
        return GraniteError.refused(["\(reason) (line \(line))"])
    }
}
