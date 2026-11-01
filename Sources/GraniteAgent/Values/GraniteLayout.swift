import Foundation

/// How a page draws what it shows.
public enum GraniteLayout: String, Codable, Sendable, CaseIterable {
    /// A list of items, refreshed by pulling, loading more at its end.
    case list
    /// A grid of items in cells that fit the width.
    case grid
    /// One item and the views that show it.
    case detail
    /// Fields bound to the page's own state, and a button that sends them.
    case form
    /// Controls bound to services' state: toggles, pickers, fields, buttons.
    case settings
    /// A search field and what it finds.
    case search
    /// Something to write: fields, a send button, a cancel button.
    case compose
    /// Views switched by a segmented control.
    case tabs
    /// A sidebar, a list and the selected item's detail, side by side.
    case threePane
    /// The page's own body, written by the host's model.
    case blank
}
