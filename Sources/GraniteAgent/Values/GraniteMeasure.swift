import Foundation
import GraniteAgents

/// What a call was asked for and what it made, as `granite-answer/1` measures it: `expected` read off the call's own
/// lines (the service its `type` names, the page, each destination, the project or kit by its name), `made` each of
/// those whose declaring file was written, `rewritten` when the file was there before.
enum GraniteMeasure {
    static func kind(_ make: GraniteMake) -> String {
        switch make {
        case .project, .link: return "project"
        case .package: return "kit"
        case .service: return "service"
        case .component: return "page"
        case .navigation: return "navigation"
        case .modals: return "modals"
        }
    }

    static func expected(_ input: GraniteAppAgent.Input) -> [AgentExpected] {
        let kind = kind(input.make)
        let type = input.type?.trimmingCharacters(in: .whitespaces) ?? ""
        let name = input.name?.trimmingCharacters(in: .whitespaces) ?? ""
        var names: [String]
        switch input.make {
        case .service: names = type.isEmpty ? [] : [SwiftName.service(type).type]
        case .component:
            names = type.isEmpty ? [] : [type.hasSuffix("Component") && type.count > 9 ? String(type.dropLast(9)) : type]
        case .navigation: names = (input.destinations ?? []).compactMap { (try? DestinationLine.parse($0))?.name }
        case .project, .package: names = name.isEmpty ? [] : [name]
        case .modals: names = ["ModalService"]
        case .link: names = ["AppRoot"]
        }
        return names.map { AgentExpected(kind: kind, name: $0) }
    }

    static func made(_ expected: [AgentExpected], make: GraniteMake, written: [String], existed: Set<String>) -> [AgentMade] {
        expected.compactMap { item in
            guard let path = file(declaring: item.name, make: make, in: written) else { return nil }
            return AgentMade(kind: item.kind, name: item.name, path: path, state: existed.contains(path) ? .rewritten : .written)
        }
    }

    /// The written file that holds what `name` is.
    static func file(declaring name: String, make: GraniteMake, in written: [String]) -> String? {
        func named(_ last: String) -> String? { written.first { ($0 as NSString).lastPathComponent == last } }
        switch make {
        case .navigation: return named("AppDestination.swift")
        case .project, .link: return named("AppRoot.swift") ?? written.first { $0.hasSuffix(".pbxproj") }
        case .package: return written.first { $0.hasSuffix("/\(name)/Package.swift") }
        case .service, .component, .modals: return named("\(name).swift")
        }
    }
}
