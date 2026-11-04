import Foundation
import GraniteAgents

/// What a call can say instead of writing.
public enum GraniteError: Error, Equatable, CustomStringConvertible, AgentRefusing {
    /// A line that is not understood, and why.
    case line(String, String)
    /// Everything the call cannot honour, each in a sentence, so all are fixed in one call. Nothing was written.
    case refused([String])
    /// The host's model never wrote what was asked of it, in every round the call allowed. Nothing was written.
    case unanswered([String])

    /// The refusal as the answer standard counts it: the call's to fix, or the model's.
    public var refusal: AgentRefusal {
        switch self {
        case .line(let line, let reason): return AgentRefusal(.call, "`\(line)`: \(reason)")
        case .refused(let reasons): return AgentRefusal(.call, reasons)
        case .unanswered(let reasons): return AgentRefusal(.model, reasons)
        }
    }

    public var description: String {
        switch self {
        case .line(let line, let reason): return "`\(line)`: \(reason)"
        case .refused(let reasons), .unanswered(let reasons):
            let count = reasons.count == 1 ? "1 problem" : "\(reasons.count) problems"
            return "\(count), so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
