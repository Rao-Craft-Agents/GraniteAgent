//  WHAT: The Granite every app and kit this package makes is built on: one URL and one commit, the same in an Xcode
//        project's package reference and in a kit's manifest, so the two resolve to one checkout.
//  PIN:  PINNED TO A REVISION. An app must build from a fresh clone years later; a branch would move under it.

import Foundation

enum GranitePin {
    static let url = "https://github.com/riteshpakala/Granite"
    static let revision = "37c762ba0e18a043c5cffbd1cd7f14d3aada3c5a"
    static let products = ["Granite", "GraniteAgents"]
}
