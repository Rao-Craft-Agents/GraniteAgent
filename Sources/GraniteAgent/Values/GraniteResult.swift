import Foundation

/// What a call answers: the files written, as absolute paths, and what they hold.
public struct GraniteResult: Codable, Sendable, Equatable {
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

    public init(path: String?, paths: [String], make: String, types: [String], notes: [String]) {
        self.path = path; self.paths = paths; self.make = make; self.types = types; self.notes = notes
    }
}
