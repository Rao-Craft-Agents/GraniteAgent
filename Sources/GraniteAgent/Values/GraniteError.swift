import Foundation

/// What a call can say instead of writing.
public enum GraniteError: Error, Equatable, CustomStringConvertible {
    /// A line that is not understood, and why.
    case line(String, String)
    /// Everything the call cannot honour, each in a sentence, so all are fixed in one call. Nothing was written.
    case refused([String])

    public var description: String {
        switch self {
        case .line(let line, let reason): return "`\(line)`: \(reason)"
        case .refused(let reasons):
            let count = reasons.count == 1 ? "1 problem" : "\(reasons.count) problems"
            return "\(count), so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
