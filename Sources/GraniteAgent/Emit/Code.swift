import Foundation

/// Swift written a line at a time, four spaces a level: what the emitters build files with.
struct Code {
    private(set) var lines: [String] = []
    private(set) var depth = 0

    init(depth: Int = 0) { self.depth = depth }

    /// A line at the current depth; an empty line stays empty.
    mutating func line(_ text: String = "") {
        lines.append(text.isEmpty ? "" : String(repeating: "    ", count: depth) + text)
    }

    /// Several lines, each at the current depth plus its own indentation.
    mutating func block(_ text: String) {
        for line in text.components(separatedBy: "\n") { self.line(line) }
    }

    /// A line that opens a scope (`Foo {`): what follows is a level deeper.
    mutating func open(_ text: String) {
        line(text)
        depth += 1
    }

    /// A line between two scopes at the outer depth (`} else {`): what follows is a level deeper again.
    mutating func middle(_ text: String) {
        depth = max(0, depth - 1)
        line(text)
        depth += 1
    }

    /// Closes a scope.
    mutating func close(_ text: String = "}") {

        depth = max(0, depth - 1)
        line(text)
    }

    /// `body` a level deeper, between `open` and `close`.
    mutating func scope(_ text: String, close: String = "}", _ body: (inout Code) -> Void) {
        open(text)
        body(&self)
        self.close(close)
    }

    /// What follows sits a level deeper, with no brace: a view's modifiers under it.
    mutating func indent() { depth += 1 }

    /// Back a level, with no brace.
    mutating func dedent() { depth = max(0, depth - 1) }

    /// A `switch` whose cases sit at its own depth, as Swift writes them.

    mutating func switchOn(_ subject: String, _ body: (inout Code) -> Void) {
        line("switch \(subject) {")
        body(&self)
        line("}")
    }

    var text: String { lines.joined(separator: "\n") + "\n" }

}
