import Foundation

/// One service as a call describes it, read and checked: what `ServiceEmitter` writes.
struct ServiceSpec {
    /// `FeedService`.
    var type: String
    /// `Feed`: the Ops' and the tests' names.
    var base: String
    /// The state, beside `loading` and `lastError`, which every service has.
    var fields: [Field]
    var events: [Event]
    /// The services the work may call, each held by the reducers whose work names it.
    var relays: [Relay]
    /// The store's persistence key; nil when the state lives only while the app runs.
    var persistKey: String?
    var isPublic = false
    var imports: [String] = []
    var doc: String?
    /// The bodies the host's model wrote, by verb.
    var bodies: [String: String] = [:]
    /// `.main` for a service work and many callers write through; `nil` for one only views bind to, so a control
    /// reads back what it wrote in the same turn.
    var setThread = ".main"

    func field(_ name: String) -> Field? { fields.first { $0.name == name } }

    /// What `event`'s work answers: the field's type when it writes the field, a page of its elements when it appends.
    func resultType(_ event: Event) -> String? {
        switch event.write {
        case .none: return nil
        case .replace(let name): return field(name)?.type.description
        case .append(let name): return field(name)?.type.element.map { "[\($0)]" }
        }
    }

    /// The reply case `event` answers with.
    func replyCase(_ event: Event) -> String? {
        switch event.write {
        case .none: return nil
        case .replace(let name): return name
        case .append(let name): return field(name)?.type.isOptional == true ? name + "Page" : name
        }
    }

    /// Whether any work writes the state: that work runs through the service's lane, one call at a time.
    var hasLane: Bool { events.contains { $0.write != .none } }

    /// The relays `event`'s work names.
    func relays(of event: Event) -> [Relay] {
        let text = event.expression ?? bodies[event.verb] ?? ""
        return relays.filter { text.range(of: #"\b\#($0.name)\b"#, options: .regularExpression) != nil }
    }

    /// The reply's cases, each once, in the order the events give them.
    var replies: [(name: String, type: String)] {
        var seen: Set<String> = []
        var cases: [(String, String)] = []
        for event in events {
            if let name = replyCase(event), let type = resultType(event), seen.insert(name).inserted { cases.append((name, type)) }
        }
        if events.contains(where: { $0.write == .none }) { cases.append(("done", "")) }
        return cases
    }
}
