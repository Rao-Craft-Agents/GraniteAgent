import Foundation
import GraniteAgents

/// What a call answers, as `granite-answer/1`: the files written, as absolute paths, what they hold, and what the call
/// made of what it asked for.
public struct GraniteResult: AgentAnswer, Equatable {
    /// The first file written.
    public var path: String?
    /// Every file written or edited, the project file and the root included.
    public var paths: [String]
    /// What the call made.
    public var make: String
    /// The types written: services, components, views, the root.
    public var types: [String]
    /// One sentence each: what the call decided, kept or left out.
    public var notes: [String]
    /// What the call made, one item each: the service, the page, each destination, the project or kit.
    public var made: [AgentMade]
    /// What the call asked for, read off its lines.
    public var expected: [AgentExpected]

    public init(path: String?, paths: [String], make: String, types: [String], notes: [String],
                made: [AgentMade] = [], expected: [AgentExpected] = []) {
        self.path = path; self.paths = paths; self.make = make; self.types = types; self.notes = notes
        self.made = made; self.expected = expected
    }
}
