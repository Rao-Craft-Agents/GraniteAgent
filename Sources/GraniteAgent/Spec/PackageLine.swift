//  WHAT: A packages line: a remote Swift package, pinned, and the products the app links.
//
//            https://github.com/kean/Nuke@<40-hex revision> Nuke NukeUI
//            https://github.com/apple/swift-collections@1.1.4 Collections
//
//  PIN:  PINNED, NEVER A BRANCH. An app must build from a fresh clone years later (the Loom layout's rule), so a
//        package is a revision or an exact version, and a branch is refused.

import Foundation

enum PackageLine {
    static func parse(_ line: String) throws -> PackageDependency {
        let words = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        guard let first = words.first, let at = first.lastIndex(of: "@"), first.hasPrefix("https://") else {
            throw GraniteError.line(line, "a package is `https://host/owner/Name@<revision or version> Product…`")
        }
        let url = String(first[..<at])
        let pin = String(first[first.index(after: at)...])
        let requirement: PackageDependency.Requirement
        if pin.range(of: #"^[0-9a-f]{40}$"#, options: .regularExpression) != nil {
            requirement = .revision(pin)
        } else if pin.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil {
            requirement = .exact(pin)
        } else {
            throw GraniteError.line(line, "`\(pin)` is neither a 40-digit revision nor a version like 1.2.3: pin the package, never a branch")
        }
        let products = Array(words.dropFirst())
        guard !products.isEmpty else { throw GraniteError.line(line, "name the products the app links after the URL, like `Nuke NukeUI`") }
        for product in products where product.range(of: #"^[A-Za-z_][A-Za-z0-9_-]*$"#, options: .regularExpression) == nil {
            throw GraniteError.line(line, "`\(product)` is not a product name")
        }
        return PackageDependency(url: url, requirement: requirement, products: products)
    }
}
