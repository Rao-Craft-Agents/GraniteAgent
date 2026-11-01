import Foundation

/// A Swift package as its manifest says it: its name, the library target a kit's code goes in, and its test target.
struct PackageInfo {
    let root: URL
    let name: String
    /// The first library target: where services go.
    let target: String
    /// The test target of that library, when the package has one.
    let testTarget: String?

    init(root: URL) {
        self.root = root
        let manifest = (try? String(contentsOf: root.appendingPathComponent("Package.swift"), encoding: .utf8)) ?? ""
        func first(_ pattern: String) -> String? {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: manifest, range: NSRange(manifest.startIndex..., in: manifest)),
                  let range = Range(match.range(at: 1), in: manifest) else { return nil }
            return String(manifest[range])
        }
        name = first(#"name:\s*"([^"]+)""#) ?? root.lastPathComponent
        target = first(#"\.target\(\s*name:\s*"([^"]+)""#) ?? name
        testTarget = first(#"\.testTarget\(\s*name:\s*"([^"]+)""#)
    }

    var sources: URL { root.appendingPathComponent("Sources/\(target)") }
    var tests: URL? { testTarget.map { root.appendingPathComponent("Tests/\($0)") } }
}
