//  WHAT: The two services every app boots on, in the service shape: `EnvironmentService` (where the boot is: idle,
//        ready or failed, and whether this is the first launch) and `ConfigService` (the appearance and the launches,
//        kept between launches), each with its one writer, its Ops and their tests.
//  PIN:  THE SETTINGS WRITER COMMITS IN THE TURN IT IS SENT (`thread: nil`): every send comes through the main-hopping
//        `set`, and a control bound to a setting reads back what it wrote (skill §8c).

import Foundation

enum BootTemplates {
    /// The files of both services, by their path under the folder services live in.
    static func files(app: String) -> [(path: String, text: String)] {
        [("EnvironmentService/EnvironmentService.swift", environment),
         ("EnvironmentService/EnvironmentService+Center.swift", environmentCenter),
         ("EnvironmentService/Reducers/EnvironmentService.Set.swift", environmentSet),
         ("EnvironmentService/Reducers/EnvironmentService.Boot.swift", environmentBoot),
         ("EnvironmentService/Ops/EnvironmentOps.swift", environmentOps),
         ("ConfigService/ConfigService.swift", config),
         ("ConfigService/ConfigService+Center.swift", configCenter(app: app)),
         ("ConfigService/Reducers/ConfigService.Set.swift", configSet),
         ("ConfigService/Ops/ConfigOps.swift", configOps),
         ("ConfigService/Models/AppAppearance.swift", appearance)]
    }

    /// The store key the settings persist under.
    static func configKey(app: String) -> String { "persistence.\(app).config.0001" }

    static let environment = """
        import Foundation
        import Granite
        import GraniteAgents

        /// Where the app is in its boot: idle until the root boots it, then ready, or failed with the reason.
        struct EnvironmentService: GraniteService {
            @Service(.online) var center: Center

            init() {}

            /// What the service's work answers whoever asked for it.
            enum Reply: Sendable {
                case done
            }

            static let tickets = GraniteTickets<Reply>()
        }

        extension EnvironmentService: @unchecked Sendable {}

        extension EnvironmentService {
            /// Changes the state through its one writer, on main.
            func set(_ kind: Set.Meta.Kind) {
                let service = self
                onMain { service.center.set.send(Set.Meta(kind: kind)) }
            }

            /// Boots the app: marks the start, then the phase it reached.
            func boot(isFirstLaunch: Bool) async throws {
                let ticket = await EnvironmentService.tickets.open()
                let service = self
                onMain { service.center.boot.send(Boot.Meta(ticket: ticket.id, isFirstLaunch: isFirstLaunch)) }
                _ = try await EnvironmentService.tickets.wait(ticket.id)
            }
        }

        """

    static let environmentCenter = """
        import Foundation
        import Granite
        import GraniteAgents

        extension EnvironmentService {
            struct Center: GraniteCenter {
                struct State: TransientState {
                    /// Where the boot is.
                    enum Phase: String, Sendable {
                        case idle
                        case ready
                        case failed
                    }

                    var phase: Phase = .idle
                    /// Whether this launch is the app's first.
                    var isFirstLaunch = false
                    /// When the app finished booting.
                    var startedAt: Date?
                    /// What is in flight, by the name of the work; nil when nothing is.
                    var loading: String?
                    /// Why the boot failed; nil once it starts again.
                    var lastError: String?

                    init() {}
                }

                @Event var set: Set.Reducer
                @Event var boot: Boot.Reducer

                @Store var state: State

                init() {}
            }
        }

        """

    static let environmentSet = """
        import Foundation
        import Granite

        extension EnvironmentService {
            /// The state's one writer: every change is a kind, applied on main by `EnvironmentOps.apply`.
            struct Set: GraniteReducer {
                typealias Center = EnvironmentService.Center
                init() {}

                struct Meta: GranitePayload {
                    enum Kind: Sendable {
                        case phase(Center.State.Phase)
                        case booted(isFirstLaunch: Bool, at: Date)
                        case loading(String?)
                        case failed(String)
                        case clear
                    }

                    var kind: Kind

                    init(kind: Kind) { self.kind = kind }
                }

                @Payload var meta: Meta?

                func reduce(state: inout Center.State) {
                    guard let meta else { return }
                    EnvironmentOps.apply(meta.kind, to: &state)
                }

                var thread: DispatchQueue? { .main }
            }
        }

        """

    static let environmentBoot = """
        import Foundation
        import Granite
        import GraniteAgents

        extension EnvironmentService {
            /// Boots the app: what was booted, and when.
            struct Boot: GraniteReducer {
                typealias Center = EnvironmentService.Center
                init() {}

                struct Meta: GranitePayload {
                    let ticket: UUID
                    let isFirstLaunch: Bool
                }

                @Payload var meta: Meta?

                /// Marks the boot's start; the state changes through `set` when it ends.
                func reduce(state: inout Center.State) {
                    guard meta != nil else { return }
                    state.loading = "boot"
                    state.lastError = nil
                }

                func effect(state: Center.State) -> GraniteEffect {
                    guard let meta else { return .none }
                    let service = Live.service(EnvironmentService.self)
                    let ticket = meta.ticket
                    let isFirstLaunch = meta.isFirstLaunch
                    return .run {
                        service.set(.booted(isFirstLaunch: isFirstLaunch, at: Date()))
                        await EnvironmentService.tickets.resolve(ticket, with: .done)
                    }
                }

                var thread: DispatchQueue? { .main }
            }
        }

        """

    static let environmentOps = """
        import Foundation

        /// Every change to EnvironmentService's state, as one function a test can run without a relay.
        enum EnvironmentOps {
            static func apply(_ kind: EnvironmentService.Set.Meta.Kind, to state: inout EnvironmentService.Center.State) {
                switch kind {
                case .phase(let phase):
                    state.phase = phase
                case .booted(let isFirstLaunch, let date):
                    state.phase = .ready
                    state.isFirstLaunch = isFirstLaunch
                    state.startedAt = date
                    state.loading = nil
                    state.lastError = nil
                case .loading(let key):
                    state.loading = key
                    if key != nil { state.lastError = nil }
                case .failed(let message):
                    state.phase = .failed
                    state.lastError = message
                    state.loading = nil
                case .clear:
                    state = .init()
                }
            }
        }

        """

    static let config = """
        import Foundation
        import Granite
        import GraniteAgents
        import SwiftUI

        /// The app's settings and its launches, kept between launches.
        struct ConfigService: GraniteService {
            @Service(.online) var center: Center

            init() {}
        }

        extension ConfigService: @unchecked Sendable {}

        extension ConfigService {
            /// Changes the settings through their one writer, on main.
            func set(_ kind: Set.Meta.Kind) {
                let service = self
                onMain { service.center.set.send(Set.Meta(kind: kind)) }
            }

            /// A binding to a setting, written through `set`: `config.binding(\\.appearance) { .appearance($0) }`.
            func binding<Value>(_ keyPath: KeyPath<Center.State, Value>, _ kind: @escaping (Value) -> Set.Meta.Kind) -> Binding<Value> {
                Binding(get: { self.state[keyPath: keyPath] }, set: { self.set(kind($0)) })
            }
        }

        """

    static func configCenter(app: String) -> String {
        """
        import Foundation
        import Granite
        import GraniteAgents

        extension ConfigService {
            struct Center: GraniteCenter {
                struct State: GraniteState {
                    /// How the app looks: as the system does, or always light or dark.
                    var appearance: AppAppearance = .system
                    /// How many times the app has launched.
                    var launches: Int = 0
                    /// When the app last launched.
                    var lastOpened: Date?
                    /// What is in flight, by the name of the work; nil when nothing is.
                    var loading: String?
                    /// Why the last change failed; nil once one starts again.
                    var lastError: String?

                    init() {}

                    enum CodingKeys: String, CodingKey {
                        case appearance
                        case launches
                        case lastOpened
                    }

                    /// A setting missing from the stored file, or stored as another type, reads as its default, so the
                    /// settings keep reading after one is added; what is in flight is never stored.
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        appearance = (try? container.decodeIfPresent(AppAppearance.self, forKey: .appearance)) ?? .system
                        launches = (try? container.decodeIfPresent(Int.self, forKey: .launches)) ?? 0
                        lastOpened = try? container.decodeIfPresent(Date.self, forKey: .lastOpened)
                    }
                }

                @Event var set: Set.Reducer

                @Store(persist: "\(configKey(app: app))", autoSave: true, preload: true) var state: State

                init() {}
            }
        }

        """
    }

    static let configSet = """
        import Foundation
        import Granite

        extension ConfigService {
            /// The settings' one writer: every change is a kind, applied by `ConfigOps.apply` in the turn it is sent.
            struct Set: GraniteReducer {
                typealias Center = ConfigService.Center
                init() {}

                struct Meta: GranitePayload {
                    enum Kind: Sendable {
                        case appearance(AppAppearance)
                        case launched(Date)
                        case reset
                        case loading(String?)
                        case failed(String)
                        case clear
                    }

                    var kind: Kind

                    init(kind: Kind) { self.kind = kind }
                }

                @Payload var meta: Meta?

                func reduce(state: inout Center.State) {
                    guard let meta else { return }
                    ConfigOps.apply(meta.kind, to: &state)
                }

                var thread: DispatchQueue? { nil }
            }
        }

        """

    static let configOps = """
        import Foundation

        /// Every change to the app's settings, as one function a test can run without a relay.
        enum ConfigOps {
            static func apply(_ kind: ConfigService.Set.Meta.Kind, to state: inout ConfigService.Center.State) {
                switch kind {
                case .appearance(let appearance):
                    state.appearance = appearance
                case .launched(let date):
                    state.launches += 1
                    state.lastOpened = date
                case .reset:
                    let launches = state.launches, lastOpened = state.lastOpened
                    state = .init()
                    state.launches = launches
                    state.lastOpened = lastOpened
                case .loading(let key):
                    state.loading = key
                    if key != nil { state.lastError = nil }
                case .failed(let message):
                    state.lastError = message
                    state.loading = nil
                case .clear:
                    state = .init()
                }
            }
        }

        """

    static let appearance = """
        import SwiftUI

        /// How the app looks: as the system does, or always light or dark.
        enum AppAppearance: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
            case system
            case light
            case dark

            var id: Self { self }

            /// The name a picker shows.
            var title: String {
                switch self {
                case .system: String(localized: "System")
                case .light: String(localized: "Light")
                case .dark: String(localized: "Dark")
                }
            }

            /// The scheme the root view prefers; nil follows the system.
            var colorScheme: ColorScheme? {
                switch self {
                case .system: nil
                case .light: .light
                case .dark: .dark
                }
            }
        }

        """

    /// The two services' Ops tests, as the app's unit tests import them.
    static func tests(name: String, module: String) -> String {
        """
        import Foundation
        import Testing
        @testable import \(module)

        /// \(name)'s boot and settings, one test a change: what the services' writers do, run without a relay.
        struct \(name)Tests {
            @Test func bootingMarksTheAppReady() {
                var state = EnvironmentService.Center.State()
                let date = Date(timeIntervalSince1970: 1_000)
                EnvironmentOps.apply(.loading("boot"), to: &state)
                EnvironmentOps.apply(.booted(isFirstLaunch: true, at: date), to: &state)
                #expect(state.phase == .ready)
                #expect(state.isFirstLaunch)
                #expect(state.startedAt == date)
                #expect(state.loading == nil)
            }

            @Test func aFailedBootSaysWhy() {
                var state = EnvironmentService.Center.State()
                EnvironmentOps.apply(.loading("boot"), to: &state)
                EnvironmentOps.apply(.failed("no network"), to: &state)
                #expect(state.phase == .failed)
                #expect(state.lastError == "no network")
                #expect(state.loading == nil)
            }

            @Test func theEnvironmentStartsOver() {
                var state = EnvironmentService.Center.State()
                EnvironmentOps.apply(.phase(.ready), to: &state)
                EnvironmentOps.apply(.clear, to: &state)
                #expect(state == EnvironmentService.Center.State())
            }

            @Test func theAppearanceIsWritten() {
                var state = ConfigService.Center.State()
                ConfigOps.apply(.appearance(.dark), to: &state)
                #expect(state.appearance == .dark)
            }

            @Test func aLaunchIsCounted() {
                var state = ConfigService.Center.State()
                let date = Date(timeIntervalSince1970: 2_000)
                ConfigOps.apply(.launched(date), to: &state)
                ConfigOps.apply(.launched(date), to: &state)
                #expect(state.launches == 2)
                #expect(state.lastOpened == date)
            }

            @Test func resettingKeepsTheLaunches() {
                var state = ConfigService.Center.State()
                ConfigOps.apply(.launched(Date(timeIntervalSince1970: 3_000)), to: &state)
                ConfigOps.apply(.appearance(.light), to: &state)
                ConfigOps.apply(.reset, to: &state)
                #expect(state.appearance == .system)
                #expect(state.launches == 1)
            }

            @Test func storedSettingsMissingAFieldStillRead() throws {
                let stored = try PropertyListEncoder().encode(["launches": 4])
                let state = try PropertyListDecoder().decode(ConfigService.Center.State.self, from: stored)
                #expect(state.launches == 4)
                #expect(state.appearance == .system)
            }

            @Test func workInFlightIsMarkedAndAFailureEndsIt() {
                var state = ConfigService.Center.State()
                ConfigOps.apply(.loading("sync"), to: &state)
                #expect(state.loading == "sync")
                ConfigOps.apply(.failed("offline"), to: &state)
                #expect(state.lastError == "offline")
                #expect(state.loading == nil)
            }
        }

        """
    }
}
