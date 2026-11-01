import Foundation

/// What a call makes.
public enum GraniteMake: String, Codable, Sendable, CaseIterable {
    /// A new iOS + macOS app: its Xcode project, folders, root, boot and settings services, and root page.
    case project
    /// A new Swift package of Granite services: a kit an app links.
    case package
    /// Granite brought into an Xcode project this agent did not make.
    case link
    /// One service: its state, its one writer, its work and its tests.
    case service
    /// One page: the component, its view-only state, its layout and its subviews.
    case component
    /// The app's destinations: tabs or a sidebar, routes, a layout service.
    case navigation
    /// The app's sheets, alerts, toasts, travelling panels and macOS windows.
    case modals
}
