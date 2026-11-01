//  WHAT: The last pass over every Swift file a call writes: a type it names that a local package of the project
//        declares is imported, once, after the file's own imports.
//  PIN:  READ OFF WHAT IS WRITTEN, NOT WHAT WAS ASKED. A row drawn from a package's type, an Ops test whose sample is a
//        package's value, a model-written body: each can name a package's type that no input line mentioned, and an
//        app target does not see a package module it does not import.

import Foundation

enum PackageImports {
    /// `plan`'s Swift files, each importing every project package module whose types it names.
    static func add(to plan: inout Plan, index: ProjectIndex) {
        guard !index.modules.isEmpty else { return }
        for (offset, file) in plan.files.enumerated() where file.url.pathExtension == "swift" {
            let own = ProjectIndex.module(of: file.url)
            let needed = modules(named: file.text, index: index).filter { $0 != own }
            guard !needed.isEmpty else { continue }
            plan.files[offset].text = inserting(needed, into: file.text)
        }
    }

    /// The package modules whose types `text` names, sorted.
    static func modules(named text: String, index: ProjectIndex) -> [String] {
        var found: Set<String> = []
        let pattern = try! NSRegularExpression(pattern: #"\b[A-Z][A-Za-z0-9_]*\b"#)
        for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text), let module = index.modules[String(text[range])] else { continue }
            found.insert(module)
        }
        return found.sorted()
    }

    /// `text` with `import <module>` for each of `modules` it does not import yet, after its last import line.
    static func inserting(_ modules: [String], into text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        let imported = Set(lines.compactMap { line -> String? in
            let words = line.split(separator: " ")
            guard let i = words.firstIndex(of: "import"), i + 1 < words.count else { return nil }
            return String(words[i + 1])
        })
        let missing = modules.filter { !imported.contains($0) }
        guard !missing.isEmpty else { return text }
        let last = lines.lastIndex { $0.hasPrefix("import ") || $0.hasPrefix("@testable import ") } ?? -1
        lines.insert(contentsOf: missing.map { "import \($0)" }, at: last + 1)
        return lines.joined(separator: "\n")
    }
}
