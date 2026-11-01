import Foundation

/// A relay a page or a reducer holds: the variable and the service it reaches.
struct Relay: Equatable, Sendable {
    var name: String
    var type: String
}
