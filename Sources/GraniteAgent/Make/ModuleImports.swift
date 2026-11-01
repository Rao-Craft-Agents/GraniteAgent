//  WHAT: The modules a file must import for the types it names: a type a local package declares (a client in
//        `Packages/LemmyKit`, a kit's model) is imported by its module, with nothing for the call to list.

import Foundation

enum ModuleImports {
    /// The modules declaring the UpperCamelCase names `texts` mention, besides `besides` (the file's own module).
    static func modules(for texts: [String], index: ProjectIndex, besides: String?) -> [String] {
        var found: [String] = []
        for text in texts {
            for name in text.matches(#"\b([A-Z][A-Za-z0-9_]*)\b"#) {
                guard let module = index.modules[name], module != besides, !found.contains(module) else { continue }
                found.append(module)
            }
        }
        return found.sorted()
    }
}
