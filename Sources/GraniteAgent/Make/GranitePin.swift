//  WHAT: The Granite every app and kit this package makes is built on: one URL and one commit, the same in an Xcode
//        project's package reference and in a kit's manifest, so the two resolve to one checkout.
//  PIN:  PINNED TO A REVISION. An app must build from a fresh clone years later; a branch would move under it.

import Foundation

enum GranitePin {
    static let url = "https://github.com/riteshpakala/Granite"
    static let revision = "deb19149d3e45f96f2f34f074d159c1adee17417"
    static let products = ["Granite", "GraniteAgents"]
}
