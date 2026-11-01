//  WHAT: The app's modals as a service: what is on screen lives in ModalService's state as values (a sheet's id and
//        detents, an alert, toasts, travelling panels, the Mac's windows), the views they show live in a registry by
//        id, and one host over the root view presents them: stacked sheets, the system's alert, toasts that put
//        themselves away, panels that stay while a person browses.
//  PIN:  STATE HOLDS IDS, THE REGISTRY HOLDS VIEWS. A view is not a value a state can compare or keep; the helper
//        puts the view in the registry before it sends the id (skill §7), so the host never finds an id without
//        its view.

import Foundation

enum ModalTemplates {
    /// The service's files, by their path inside its folder.
    static let service: [(path: String, text: String)] = [
        ("ModalService.swift", modalService), ("ModalService+Center.swift", center), ("Reducers/ModalService.Set.swift", writer),
        ("Ops/ModalOps.swift", ops), ("Models/ModalSheet.swift", sheet), ("Models/ModalDetent.swift", detent),
        ("Models/ModalAlert.swift", alert), ("Models/ModalToast.swift", toast), ("Models/ModalPanel.swift", panel),
        ("Views/ModalSheetHost.swift", sheetHost), ("Views/ModalAlertHost.swift", alertHost), ("Views/ModalToastView.swift", toastView),
        ("Views/ModalPanelView.swift", panelView),
    ]

    static let modalService = """
        import Foundation
        import Granite
        import GraniteAgents
        import SwiftUI
        #if os(macOS)
        import AppKit
        #endif

        /// The app's modals: sheets, alerts, toasts, panels that travel with a person through the app, and on the Mac
        /// windows of their own. Any page, menu or service presents one through it; the root view hosts them.
        struct ModalService: GraniteService {
            @Service(.online) var center: Center

            init() {}

            /// The views the modals on screen show, by id: a view cannot live in state, so the state keeps its id.
            static let views = TransientRegistry<AnyView>()

            #if os(macOS)
            /// The windows open, by id, and what forgets each when it closes.
            static let windows = TransientRegistry<NSWindow>()
            static let closings = TransientRegistry<NSObjectProtocol>()
            #endif

            /// The registry key of a travelling panel's view.
            static func panelKey(_ id: String) -> String { "panel/\\(id)" }
        }

        extension ModalService: @unchecked Sendable {}

        extension ModalService {
            /// Changes what is on screen through its one writer, on main.
            func set(_ kind: Set.Meta.Kind) {
                let service = self
                onMain { service.center.set.send(Set.Meta(kind: kind)) }
            }

            /// Presents `content` as a sheet over the app (over the sheet on screen, when there is one): at `detents`
            /// on iPhone and iPad, on the window on the Mac. Presenting an id again replaces its content.
            @MainActor
            func sheet<Content: View>(id: String = "sheet", detents: [ModalDetent] = [.large], @ViewBuilder content: () -> Content) {
                ModalService.views.put(id, AnyView(content()))
                set(.presented(ModalSheet(id: id, detents: detents)))
            }

            /// Closes the sheet `id`, and every sheet above it.
            func dismiss(_ id: String = "sheet") {
                set(.dismissed(id))
            }

            /// Shows an alert; a button does what it says, then the alert closes.
            func alert(_ alert: ModalAlert) {
                set(.alerted(alert))
            }

            /// Shows a message over the app for a few seconds; a tap puts it away sooner.
            func toast(_ message: String, style: ModalToast.Style = .info) {
                let toast = ModalToast(message: message, style: style)
                set(.toasted(toast))
                let service = self
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    service.set(.toastExpired(toast.id))
                }
            }

            /// Opens a panel that stays over the app while a person browses (a draft, a player), until it is closed.
            @MainActor
            func travel<Content: View>(id: String, title: String, @ViewBuilder content: () -> Content) {
                ModalService.views.put(ModalService.panelKey(id), AnyView(content()))
                set(.travelled(ModalPanel(id: id, title: title)))
            }

            /// Folds the panel `id` into a chip with its title.
            func minimize(_ id: String) {
                set(.minimized(id))
            }

            /// Opens the panel `id` again.
            func restore(_ id: String) {
                set(.restored(id))
            }

            /// Closes the panel `id`.
            func close(_ id: String) {
                set(.closed(id))
                ModalService.views.remove(ModalService.panelKey(id))
            }

            #if os(macOS)
            /// Opens `content` in a window of its own, or brings forward the one already open under `id`.
            @MainActor
            func window<Content: View>(id: String, title: String, size: CGSize = CGSize(width: 480, height: 640), @ViewBuilder content: () -> Content) {
                if let open = ModalService.windows.get(id) {
                    open.makeKeyAndOrderFront(nil)
                    return
                }
                let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                                      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
                window.title = title
                window.isReleasedWhenClosed = false
                window.contentViewController = NSHostingController(rootView: content())
                window.center()
                ModalService.windows.put(id, window)
                let service = self
                let closing = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
                    ModalService.windows.remove(id)
                    if let observer = ModalService.closings.remove(id) { NotificationCenter.default.removeObserver(observer) }
                    service.set(.windowClosed(id))
                }
                ModalService.closings.put(id, closing)
                window.makeKeyAndOrderFront(nil)
                set(.windowOpened(id))
            }
            #endif
        }

        """

    static let center = """
        import Foundation
        import Granite
        import GraniteAgents

        extension ModalService {
            struct Center: GraniteCenter {
                struct State: TransientState {
                    /// The sheets on screen, the lowest first.
                    var sheets: [ModalSheet] = []
                    /// The alert on screen.
                    var alert: ModalAlert?
                    /// The toasts on screen, the newest last.
                    var toasts: [ModalToast] = []
                    /// The panels travelling with the person.
                    var panels: [ModalPanel] = []
                    /// The ids of the Mac windows open.
                    var windows: [String] = []

                    init() {}
                }

                @Event var set: Set.Reducer

                @Store var state: State

                init() {}
            }
        }

        """

    static let writer = """
        import Foundation
        import Granite

        extension ModalService {
            /// What is on screen has one writer: every change is a kind, applied by `ModalOps.apply` in the turn it is sent.
            struct Set: GraniteReducer {
                typealias Center = ModalService.Center
                init() {}

                struct Meta: GranitePayload {
                    enum Kind: Sendable {
                        case presented(ModalSheet)
                        case dismissed(String)
                        case alerted(ModalAlert?)
                        case toasted(ModalToast)
                        case toastExpired(UUID)
                        case travelled(ModalPanel)
                        case minimized(String)
                        case restored(String)
                        case closed(String)
                        case windowOpened(String)
                        case windowClosed(String)
                        case clear
                    }

                    var kind: Kind

                    init(kind: Kind) { self.kind = kind }
                }

                @Payload var meta: Meta?

                func reduce(state: inout Center.State) {
                    guard let meta else { return }
                    ModalOps.apply(meta.kind, to: &state)
                }

                var thread: DispatchQueue? { nil }
            }
        }

        """

    static let ops = """
        import Foundation

        /// Every change to what is on screen, as one function a test can run without a relay.
        enum ModalOps {
            /// How many toasts show at once; an older one gives way.
            static let toastLimit = 3

            static func apply(_ kind: ModalService.Set.Meta.Kind, to state: inout ModalService.Center.State) {
                switch kind {
                case .presented(let sheet):
                    if let index = state.sheets.firstIndex(where: { $0.id == sheet.id }) {
                        state.sheets[index] = sheet
                    } else {
                        state.sheets.append(sheet)
                    }
                case .dismissed(let id):
                    if let index = state.sheets.firstIndex(where: { $0.id == id }) {
                        state.sheets.removeSubrange(index...)
                    }
                case .alerted(let alert):
                    state.alert = alert
                case .toasted(let toast):
                    state.toasts.append(toast)
                    if state.toasts.count > toastLimit { state.toasts.removeFirst(state.toasts.count - toastLimit) }
                case .toastExpired(let id):
                    state.toasts.removeAll { $0.id == id }
                case .travelled(let panel):
                    if let index = state.panels.firstIndex(where: { $0.id == panel.id }) {
                        state.panels[index] = panel
                    } else {
                        state.panels.append(panel)
                    }
                case .minimized(let id):
                    if let index = state.panels.firstIndex(where: { $0.id == id }) { state.panels[index].isMinimized = true }
                case .restored(let id):
                    if let index = state.panels.firstIndex(where: { $0.id == id }) { state.panels[index].isMinimized = false }
                case .closed(let id):
                    state.panels.removeAll { $0.id == id }
                case .windowOpened(let id):
                    if !state.windows.contains(id) { state.windows.append(id) }
                case .windowClosed(let id):
                    state.windows.removeAll { $0 == id }
                case .clear:
                    state = .init()
                }
            }
        }

        """

    static let sheet = """
        import Foundation

        /// A sheet on screen: its id (its view is in ModalService's registry under it) and the heights it may rest at.
        struct ModalSheet: Equatable, Identifiable, Sendable {
            let id: String
            var detents: [ModalDetent]
        }

        """

    static let detent = """
        import SwiftUI

        /// A height a sheet rests at on iPhone and iPad.
        enum ModalDetent: String, CaseIterable, Sendable {
            case medium
            case large

            /// SwiftUI's own.
            var detent: PresentationDetent {
                switch self {
                case .medium: .medium
                case .large: .large
                }
            }
        }

        """

    static let alert = """
        import Foundation
        import SwiftUI

        /// An alert: a title, a message, and its buttons. Two alerts are the same when they are the same one, by id.
        struct ModalAlert: Equatable, Identifiable, Sendable {
            /// One button: its words, its role, and what it does when pressed.
            struct Action: Identifiable, Sendable {
                enum Role: Sendable {
                    case normal
                    case cancel
                    case destructive

                    var buttonRole: ButtonRole? {
                        switch self {
                        case .normal: nil
                        case .cancel: .cancel
                        case .destructive: .destructive
                        }
                    }
                }

                let id = UUID()
                let title: String
                let role: Role
                let perform: @MainActor @Sendable () -> Void

                init(title: String, role: Role = .normal, perform: @escaping @MainActor @Sendable () -> Void = {}) {
                    self.title = title
                    self.role = role
                    self.perform = perform
                }

                /// A button that does `perform`.
                static func `default`(_ title: String, perform: @escaping @MainActor @Sendable () -> Void = {}) -> Action {
                    Action(title: title, perform: perform)
                }

                /// A button that closes the alert and does nothing else.
                static func cancel(_ title: String = String(localized: "Cancel")) -> Action {
                    Action(title: title, role: .cancel)
                }

                /// A button that takes something away.
                static func destructive(_ title: String, perform: @escaping @MainActor @Sendable () -> Void) -> Action {
                    Action(title: title, role: .destructive, perform: perform)
                }
            }

            let id = UUID()
            var title: String
            var message: String?
            var actions: [Action]

            init(title: String, message: String? = nil, actions: [Action] = [.default(String(localized: "OK"))]) {
                self.title = title
                self.message = message
                self.actions = actions
            }

            static func == (a: ModalAlert, b: ModalAlert) -> Bool { a.id == b.id }
        }

        """

    static let toast = """
        import Foundation

        /// A message over the app for a few seconds.
        struct ModalToast: Equatable, Identifiable, Sendable {
            /// What the message is: said by its symbol and its colour.
            enum Style: String, Sendable {
                case info
                case success
                case warning
                case error
            }

            let id = UUID()
            var message: String
            var style: Style
        }

        """

    static let panel = """
        import Foundation

        /// A panel that stays over the app while a person browses: open, or minimized to its title.
        struct ModalPanel: Equatable, Identifiable, Sendable {
            let id: String
            var title: String
            var isMinimized = false
        }

        """

    static let sheetHost = """
        import Granite
        import SwiftUI

        /// The sheet at `level` of ModalService's stack, presented over the view; its content presents the next one.
        struct ModalSheetHost: ViewModifier {
            let level: Int
            @Relay var modals: ModalService

            func body(content: Content) -> some View {
                content.sheet(item: sheet) { sheet in
                    (ModalService.views.get(sheet.id) ?? AnyView(EmptyView()))
                        .modifier(ModalSheetHost(level: level + 1))
                        .presentationDetents(Swift.Set(sheet.detents.map(\\.detent)))
                }
            }

            /// The sheet at this level; dismissing it closes it and every sheet above it.
            private var sheet: Binding<ModalSheet?> {
                Binding(get: { modals.state.sheets.indices.contains(level) ? modals.state.sheets[level] : nil },
                        set: { sheet in
                            guard sheet == nil, modals.state.sheets.indices.contains(level) else { return }
                            modals.dismiss(modals.state.sheets[level].id)
                        })
            }
        }

        """

    static let alertHost = """
        import Granite
        import SwiftUI

        /// The alert ModalService holds, presented with the system's alert as it was when it was asked for.
        struct ModalAlertHost: ViewModifier {
            @Relay var modals: ModalService

            func body(content: Content) -> some View {
                content.alert(modals.state.alert?.title ?? "", isPresented: isPresented, presenting: modals.state.alert) { alert in
                    ForEach(alert.actions) { action in
                        Button(action.title, role: action.role.buttonRole) { action.perform() }
                    }
                } message: { alert in
                    if let message = alert.message { Text(message) }
                }
            }

            private var isPresented: Binding<Bool> {
                Binding(get: { modals.state.alert != nil }, set: { shown in if !shown { modals.set(.alerted(nil)) } })
            }
        }

        """

    static let toastView = """
        import SwiftUI

        /// A message over the app for a few seconds; a tap puts it away.
        struct ModalToastView: View {
            let toast: ModalToast
            var dismiss: () -> Void

            var body: some View {
                Label {
                    Text(toast.message)
                } icon: {
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                }
                .font(.callout.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(tint.opacity(0.35)))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .onTapGesture(perform: dismiss)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("Puts the message away"))
            }

            private var symbol: String {
                switch toast.style {
                case .info: "info.circle.fill"
                case .success: "checkmark.circle.fill"
                case .warning: "exclamationmark.triangle.fill"
                case .error: "xmark.octagon.fill"
                }
            }

            private var tint: Color {
                switch toast.style {
                case .info: .accentColor
                case .success: .green
                case .warning: .orange
                case .error: .red
                }
            }
        }

        """

    static let panelView = """
        import SwiftUI

        /// A panel that stays over the app while a person browses: open with its content under a header that minimizes
        /// or closes it, or minimized to a chip with its title.
        struct ModalPanelView: View {
            let panel: ModalPanel
            let content: AnyView?
            var minimize: () -> Void
            var restore: () -> Void
            var close: () -> Void

            var body: some View {
                if panel.isMinimized {
                    Button(action: restore) {
                        Label(panel.title, systemImage: "rectangle.on.rectangle")
                            .font(.callout.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Opens the panel"))
                } else {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Text(panel.title)
                                .font(.headline)
                            Spacer(minLength: 8)
                            Button(action: minimize) {
                                Image(systemName: "minus")
                            }
                            .accessibilityLabel(Text("Minimize"))
                            Button(action: close) {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel(Text("Close"))
                        }
                        .buttonStyle(.borderless)
                        .padding(12)
                        Divider()
                        (content ?? AnyView(EmptyView()))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: 380)
                    .frame(height: 420)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
                }
            }
        }

        """

    /// The real host the root view applies: every modal ModalService holds, over the view.
    static let hosting = """
        import Granite
        import SwiftUI

        extension View {
            /// Hosts the app's sheets, alerts, toasts and travelling panels over this view. The root view applies it once.
            func modalHosted() -> some View {
                modifier(ModalHosting())
            }
        }

        /// What ModalService holds, presented over the view it is applied to.
        struct ModalHosting: ViewModifier {
            @Relay var modals: ModalService
            @StateObject private var clock = RelayClock([RelayClock.on(ModalService.self)])

            func body(content: Content) -> some View {
                content
                    .modifier(ModalSheetHost(level: 0))
                    .modifier(ModalAlertHost())
                    .overlay(alignment: .top) {
                        VStack(spacing: 8) {
                            ForEach(modals.state.toasts) { toast in
                                ModalToastView(toast: toast) { modals.set(.toastExpired(toast.id)) }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.top, 8)
                        .animation(.spring(duration: 0.3), value: modals.state.toasts)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing, spacing: 8) {
                            ForEach(modals.state.panels) { panel in
                                ModalPanelView(panel: panel, content: ModalService.views.get(ModalService.panelKey(panel.id)),
                                               minimize: { modals.minimize(panel.id) },
                                               restore: { modals.restore(panel.id) },
                                               close: { modals.close(panel.id) })
                            }
                        }
                        .padding()
                        .animation(.spring(duration: 0.3), value: modals.state.panels)
                    }
            }
        }

        """

    static func tests(module: String) -> String {
        """
        import Foundation
        import Testing
        @testable import \(module)

        /// What is on screen, one test a change: what ModalService's writer does, run without a relay.
        struct ModalOpsTests {
            @Test func sheetsStackAndADismissClosesTheOnesAbove() {
                var state = ModalService.Center.State()
                ModalOps.apply(.presented(ModalSheet(id: "compose", detents: [.large])), to: &state)
                ModalOps.apply(.presented(ModalSheet(id: "pick", detents: [.medium])), to: &state)
                #expect(state.sheets.map(\\.id) == ["compose", "pick"])
                ModalOps.apply(.dismissed("compose"), to: &state)
                #expect(state.sheets.isEmpty)
            }

            @Test func presentingAnIdAgainReplacesIt() {
                var state = ModalService.Center.State()
                ModalOps.apply(.presented(ModalSheet(id: "compose", detents: [.large])), to: &state)
                ModalOps.apply(.presented(ModalSheet(id: "compose", detents: [.medium])), to: &state)
                #expect(state.sheets == [ModalSheet(id: "compose", detents: [.medium])])
            }

            @Test func anAlertShowsAndCloses() {
                var state = ModalService.Center.State()
                let alert = ModalAlert(title: "Sample", actions: [.cancel()])
                ModalOps.apply(.alerted(alert), to: &state)
                #expect(state.alert == alert)
                ModalOps.apply(.alerted(nil), to: &state)
                #expect(state.alert == nil)
            }

            @Test func toastsGiveWayAndExpire() {
                var state = ModalService.Center.State()
                let toasts = (0..<4).map { ModalToast(message: "Toast \\($0)", style: .info) }
                for toast in toasts { ModalOps.apply(.toasted(toast), to: &state) }
                #expect(state.toasts.count == ModalOps.toastLimit)
                #expect(state.toasts.first == toasts[1])
                ModalOps.apply(.toastExpired(toasts[3].id), to: &state)
                #expect(!state.toasts.contains(toasts[3]))
            }

            @Test func aPanelMinimizesRestoresAndCloses() {
                var state = ModalService.Center.State()
                ModalOps.apply(.travelled(ModalPanel(id: "draft", title: "Draft")), to: &state)
                ModalOps.apply(.minimized("draft"), to: &state)
                #expect(state.panels.first?.isMinimized == true)
                ModalOps.apply(.restored("draft"), to: &state)
                #expect(state.panels.first?.isMinimized == false)
                ModalOps.apply(.closed("draft"), to: &state)
                #expect(state.panels.isEmpty)
            }

            @Test func windowsAreCountedOnce() {
                var state = ModalService.Center.State()
                ModalOps.apply(.windowOpened("inspector"), to: &state)
                ModalOps.apply(.windowOpened("inspector"), to: &state)
                #expect(state.windows == ["inspector"])
                ModalOps.apply(.windowClosed("inspector"), to: &state)
                #expect(state.windows.isEmpty)
            }

            @Test func clearStartsOver() {
                var state = ModalService.Center.State()
                ModalOps.apply(.travelled(ModalPanel(id: "draft", title: "Draft")), to: &state)
                ModalOps.apply(.clear, to: &state)
                #expect(state == ModalService.Center.State())
            }
        }

        """
    }
}
