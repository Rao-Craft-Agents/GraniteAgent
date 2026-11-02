//  WHAT: What a project already holds, read off its Swift: its services (their state, writer kinds, entries and the
//        services their reducers relay to), its pages, its types (their fields, cases and previews), and its roots.
//        A call reads it to bind a page to a service's real fields, to refuse a relay cycle, and to add a service to
//        the root that holds the relays.
//  PIN:  READ, NOT COMPILED. Declarations are found by their shape on a line, as this family's agents and Xcode's
//        templates write them; what is not found is said in a note, never guessed.

import Foundation

struct ProjectIndex {
    struct ServiceInfo {
        let name: String
        let file: URL
        var fields: [(name: String, type: String)] = []
        var kinds: [String] = []
        var entries: [String] = []
        var signatures: [String] = []
        /// The services this one's reducers hold relays to.
        var relays: [String] = []
        var isPublic = false

        func field(_ name: String) -> String? { fields.first { $0.name == name }?.type }
    }

    struct TypeInfo {
        let name: String
        let kind: String
        let conformances: [String]
        var fields: [(name: String, type: String)] = []
        var cases: [String] = []
        var hasTitle = false

        var isCaseIterable: Bool { conformances.contains("CaseIterable") }

    }

    var services: [String: ServiceInfo] = [:]
    var components: [String: URL] = [:]
    var types: [String: TypeInfo] = [:]
    var previews: Set<String> = []
    var appRoot: URL?
    /// Files declaring a kit's root (`@MainActor public final class <Name>Root`).
    var kitRoots: [String: URL] = [:]
    var hasRelayClock = false
    var swiftFiles: [URL] = []
    /// The module a type is declared in, when it is a local package's (`Packages/<Kit>/Sources/<Module>/…`).
    var modules: [String: String] = [:]
    /// What each function answers, by its name, as declared anywhere: a client's `posts(page:)` answers `PostPage`.
    var returns: [String: Set<String>] = [:]
    /// Each type's shape as written: its declaration, its initializers, its cases and its stored fields, one line
    /// each. A page's body is asked for with the shapes of the views it shows (`FeedView`, `SocialActions`).
    var shapes: [String: [String]] = [:]


    /// Every type declared anywhere, by name.
    var declared: Set<String> { Set(types.keys).union(services.keys).union(components.keys) }

    init() {}

    /// Reads every Swift file under `root`, skipping build products, project bundles and test folders.
    init(root: URL) {
        for url in Self.swiftFiles(under: root, skipping: Self.skipped) {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            swiftFiles.append(url)
            read(text, at: url)
        }
        for (name, service) in services { services[name] = complete(service) }
    }

    /// Folders a walk never enters: build products, version control, test targets.
    static let skipped: Set<String> = [".build", ".git", ".swiftpm", "DerivedData", "node_modules", "Tests", "UITests"]

    /// The Swift files under `root`, as `root` names them: a walk by relative path, so a folder the host named through
    /// a link (`/var` for `/private/var`) keeps the host's spelling in every answer.
    static func swiftFiles(under root: URL, skipping: Set<String>) -> [URL] {
        guard let walker = FileManager.default.enumerator(atPath: root.path) else { return [] }
        var found: [URL] = []
        while let relative = walker.nextObject() as? String {
            let name = (relative as NSString).lastPathComponent
            if walker.fileAttributes?[.type] as? FileAttributeType == .typeDirectory {
                if skipping.contains(name) || name.hasPrefix(".") || name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcassets")
                    || name.hasSuffix("Tests") { walker.skipDescendants() }
                continue
            }
            if name.hasSuffix(".swift") { found.append(root.appendingPathComponent(relative)) }
        }
        return found
    }

    private static let typePattern = try! NSRegularExpression(
        pattern: #"^([ \t]*)(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|internal|fileprivate|private|open|final|indirect)\s+)*(struct|enum|class|actor)\s+([A-Z]\w*)(?:<[^>{]*>)?\s*(?::\s*([^{]+?))?\s*\{"#,
        options: [.anchorsMatchLines])

    private mutating func read(_ text: String, at url: URL) {
        let lines = text.components(separatedBy: "\n")
        for match in Self.typePattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let indentRange = Range(match.range(at: 1), in: text), let kindRange = Range(match.range(at: 2), in: text),
                  let nameRange = Range(match.range(at: 3), in: text) else { continue }
            let indent = text[indentRange].count
            let kind = String(text[kindRange]), name = String(text[nameRange])
            let conformances = Range(match.range(at: 4), in: text).map { text[$0].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } } ?? []
            if conformances.contains("GraniteService") {
                var service = ServiceInfo(name: name, file: url)
                service.isPublic = text.contains("public struct \(name)")
                services[name] = service
            }
            if conformances.contains("GraniteComponent") { components[name] = url }
            guard indent == 0 else { continue }
            if let module = Self.module(of: url) { modules[name] = module }
            let line = text[..<nameRange.lowerBound].components(separatedBy: "\n").count - 1

            if shapes[name] == nil { shapes[name] = Self.shape(of: lines, from: line, indent: indent) }
            var info = TypeInfo(name: name, kind: kind, conformances: conformances)
            let (fields, cases, hasTitle) = Self.members(of: lines, from: line, indent: indent)
            info.fields = fields; info.cases = cases; info.hasTitle = hasTitle
            if types[name] == nil || types[name]?.fields.isEmpty == true { types[name] = info }
        }
        for (name, type) in Self.functionReturns(in: text) { returns[name, default: []].insert(type) }
        for match in text.matches(#"static (?:let|var) preview: ([A-Z]\w*)"#) { previews.insert(match) }
        if text.contains("final class AppRoot") { appRoot = url }
        for root in text.matches(#"(?:public )?final class ([A-Z]\w*Root)\b"#) where root != "AppRoot" { kitRoots[root] = url }
        if text.contains("final class RelayClock") { hasRelayClock = true }
    }

    /// Each `func name(…) async throws -> Type` in `text`, by name and answer, its parameters on any number of lines.
    static func functionReturns(in text: String) -> [(name: String, type: String)] {
        let source = text as NSString
        guard let pattern = try? NSRegularExpression(pattern: #"\bfunc\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:<[^>{]*>)?\s*\("#) else { return [] }
        var found: [(name: String, type: String)] = []
        for match in pattern.matches(in: text, range: NSRange(location: 0, length: source.length)) {
            var position = match.range.location + match.range.length, depth = 1
            while position < source.length, depth > 0 {
                let unit = source.character(at: position)
                if unit == 40 { depth += 1 } else if unit == 41 { depth -= 1 }
                position += 1
            }
            guard depth == 0 else { continue }
            // After the parameters: the effects, then `-> Type`, up to the body, a `where` or the line's end.
            let head = source.substring(from: position).prefix { $0 != "{" && $0 != "\n" }
            guard let arrow = head.range(of: "->") else { continue }
            var type = head[arrow.upperBound...].trimmingCharacters(in: .whitespaces)
            if let clause = type.range(of: " where ") { type = String(type[..<clause.lowerBound]).trimmingCharacters(in: .whitespaces) }
            if !type.isEmpty { found.append((source.substring(with: match.range(at: 1)), type)) }
        }
        return found
    }

    /// The module a file of a package compiles into: the folder under `Sources/`.
    static func module(of url: URL) -> String? {
        let parts = url.pathComponents
        guard let sources = parts.lastIndex(of: "Sources"), sources + 1 < parts.count - 1,
              FileManager.default.fileExists(atPath: NSString.path(withComponents: Array(parts[..<sources])) + "/Package.swift") else { return nil }
        return parts[sources + 1]
    }

    /// The shape of the type whose declaration is on `line`: the declaration up to its `{`, then one level in each
    /// initializer's signature (on any number of lines), each case and each stored field, as written.
    static func shape(of lines: [String], from line: Int, indent: Int) -> [String] {
        var shape = [lines[line].components(separatedBy: "{")[0].trimmingCharacters(in: .whitespaces)]
        let inner = String(repeating: " ", count: indent + 4)
        var index = line + 1
        while index < lines.count {
            let text = lines[index]
            if text.hasPrefix(String(repeating: " ", count: indent) + "}") && !text.hasPrefix(inner) { break }
            if text.hasPrefix(inner), !text.hasPrefix(inner + " ") {
                let body = String(text.dropFirst(inner.count)).replacingOccurrences(of: "public ", with: "")
                if body.hasPrefix("case ") || Self.storedField(body) != nil {
                    shape.append(body.trimmingCharacters(in: .whitespaces))
                } else if body.range(of: #"^(?:@\w+ )*(?:convenience )?init[?!]?\("#, options: .regularExpression) != nil {
                    var signature = body, depth = 0, cursor = index
                    func balance(_ text: String) -> Int { text.filter { $0 == "(" }.count - text.filter { $0 == ")" }.count }
                    depth = balance(body)
                    while depth > 0, cursor + 1 < lines.count {
                        cursor += 1
                        signature += " " + lines[cursor].trimmingCharacters(in: .whitespaces)
                        depth += balance(lines[cursor])
                    }
                    shape.append(signature.components(separatedBy: "{")[0].trimmingCharacters(in: .whitespaces))
                    index = cursor
                }
            }
            index += 1
        }
        return shape
    }

    /// The stored fields, cases and `title` of the type whose declaration is on `line`: what sits one level in.

    static func members(of lines: [String], from line: Int, indent: Int) -> ([(name: String, type: String)], [String], Bool) {
        var fields: [(name: String, type: String)] = [], cases: [String] = [], hasTitle = false
        let inner = String(repeating: " ", count: indent + 4)
        var index = line + 1
        while index < lines.count {
            let text = lines[index]
            if text.hasPrefix(String(repeating: " ", count: indent) + "}") && !text.hasPrefix(inner) { break }
            if text.hasPrefix(inner), !text.hasPrefix(inner + " ") {
                let body = String(text.dropFirst(inner.count))
                if let field = Self.storedField(body) { fields.append(field) }
                if body.hasPrefix("case ") {
                    for piece in body.dropFirst(5).split(separator: ",") {
                        let name = piece.trimmingCharacters(in: .whitespaces).prefix { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "`" }
                        if !name.isEmpty { cases.append(String(name).trimmingCharacters(in: CharacterSet(charactersIn: "`"))) }
                    }
                }
                if body.range(of: #"^(?:public )?var title: (?:String|LocalizedStringKey|LocalizedStringResource)"#, options: .regularExpression) != nil { hasTitle = true }
            }
            index += 1
        }
        return (fields, cases, hasTitle)
    }

    /// `var title: String`, `public let id: UUID = UUID()`; nil for a computed property or anything static.
    static func storedField(_ line: String) -> (name: String, type: String)? {
        guard let regex = try? NSRegularExpression(pattern: #"^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|internal|private|fileprivate)(?:\(set\))?\s+)*(?:var|let)\s+(`?\w+`?)\s*:\s*([^={]+?)\s*(=.*)?$"#),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let name = Range(match.range(at: 1), in: line), let type = Range(match.range(at: 2), in: line) else { return nil }
        if line.contains("{") && Range(match.range(at: 3), in: line) == nil { return nil }
        return (String(line[name]).trimmingCharacters(in: CharacterSet(charactersIn: "`")), String(line[type]).trimmingCharacters(in: .whitespaces))
    }

    /// A service's state, writer, entries and relays, read off the files in its folder.
    private func complete(_ service: ServiceInfo) -> ServiceInfo {
        var service = service
        let folder = service.file.deletingLastPathComponent()
        let files = Self.swiftFiles(under: folder, skipping: [])
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8), text.contains("extension \(service.name)") || file == service.file else { continue }
            let lines = text.components(separatedBy: "\n")
            if let state = lines.firstIndex(where: { $0.range(of: #"^\s*(?:public )?struct State\s*:"#, options: .regularExpression) != nil }) {
                let indent = lines[state].prefix { $0 == " " }.count
                service.fields = Self.members(of: lines, from: state, indent: indent).0
            }
            if let kind = lines.firstIndex(where: { $0.range(of: #"^\s*(?:public )?enum Kind\s*:"#, options: .regularExpression) != nil }) {
                let indent = lines[kind].prefix { $0 == " " }.count
                service.kinds = Self.members(of: lines, from: kind, indent: indent).1
            }
            if file.path.contains("/Reducers/") {
                service.relays += text.matches(#"@Relay(?:\([^)]*\))?\s+(?:public |private |internal )?var \w+\s*:\s*([A-Z]\w*)"#)
            }
            if file == service.file {
                for line in lines where line.range(of: #"^\s*(?:public )?func \w+"#, options: .regularExpression) != nil {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    let signature = trimmed.hasSuffix("{") ? String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces) : trimmed
                    if let name = signature.matches(#"func (\w+)"#).first { service.entries.append(name) }
                    service.signatures.append(signature)
                }
            }
        }
        return service
    }

    // MARK: - Reading an expression

    /// The type of `expression` when it reads a service's or the page's state: `feed.state.posts` through the relay
    /// `feed`, `state.query` through `own` (the page's fields). Nil when it is anything else.
    func type(of expression: String, relays: [Relay], own: [Field]) -> String? {
        let parts = expression.trimmingCharacters(in: .whitespaces).split(separator: ".").map(String.init)
        if parts.count == 3, parts[1] == "state", let relay = relays.first(where: { $0.name == parts[0] }) {
            return services[relay.type]?.field(parts[2])
        }
        if parts.count == 2, parts[0] == "state" { return own.first { $0.name == parts[1] }?.type.description }
        return nil
    }

    /// Whether the service `name` (a `make: service` one) writes `field` through a `set` kind of its own name.
    func isBindable(_ service: String, field: String) -> Bool {
        guard let info = services[service] else { return false }
        return info.kinds.contains(field) && info.entries.contains("binding")
    }

    /// Whether a relay from `from` to `to` closes a loop: `to`'s reducers reach `from`, directly or through others.
    func reaches(_ from: String, _ to: String) -> Bool {
        var seen: Set<String> = [], stack = [from]
        while let name = stack.popLast() {
            guard seen.insert(name).inserted, let service = services[name] else { continue }
            if service.relays.contains(to) { return true }
            stack += service.relays
        }
        return false
    }
}

extension String {
    /// The first capture of every match of `pattern`.
    func matches(_ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: self, range: NSRange(startIndex..., in: self)).compactMap { match in
            Range(match.range(at: match.numberOfRanges > 1 ? 1 : 0), in: self).map { String(self[$0]) }
        }
    }
}
