import Foundation

/// What a run says as it goes.
public enum GraniteFrame: Sendable {
    /// The call was read: what it makes and how many lines it gave.
    case read(make: GraniteMake, lines: Int)
    /// The host's model wrote a body: for which type, in how many rounds.
    case asked(type: String, rounds: Int)
    /// The files are written.
    case written(GraniteResult)

    public var result: GraniteResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
