//  WHAT: Small app-wide helpers a page needs and the project may not have yet: the relay clock that keeps bound
//        controls up with their service.

import Foundation

enum UtilityTemplates {
    /// PIN (skill §6b): a relay re-draws its views through a 0.2 s debounce; a control bound to a service reads back
    /// its own change a frame later only when its page holds a clock on that service.
    static let relayClock = """
        import Combine
        import Granite
        import SwiftUI

        /// Re-draws the view that holds it within a frame of a change to the services it follows: what a page with
        /// controls bound to a service holds, so a toggle or a picker reads back its own change at once.
        @MainActor
        final class RelayClock: ObservableObject {
            private var bag: [AnyCancellable] = []

            init(_ signals: [AnyPublisher<Void, Never>]) {
                Publishers.MergeMany(signals)
                    .throttle(for: .milliseconds(16), scheduler: DispatchQueue.main, latest: true)
                    .sink { [weak self] _ in self?.objectWillChange.send() }
                    .store(in: &bag)
            }

            /// The change signal of a service's shared relay.
            static func on<S: GraniteService>(_ type: S.Type) -> AnyPublisher<Void, Never> {
                Relay<S>().relay.objectWillChange.map { _ in () }.eraseToAnyPublisher()
            }
        }

        """
}
