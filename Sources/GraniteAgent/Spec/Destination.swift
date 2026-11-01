import Foundation

/// One of the app's destinations, as a destinations line says it: `feed: Feed "Feed" house`.
struct Destination: Equatable, Sendable {
    /// The case of `AppDestination`.
    var name: String
    /// The view it shows: `Feed()` or `Feed(kind: .all)`.
    var view: String
    /// The view's type.
    var viewType: String
    var title: String
    var symbol: String
    /// The view the detail pane shows beside it, in the split style.
    var detail: String?
    var detailType: String?
}
