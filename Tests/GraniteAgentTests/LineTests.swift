import XCTest
@testable import GraniteAgent

/// The lines a model writes, read: every form the guide promises, and a reason for every line refused.
final class LineTests: XCTestCase {
    func testEventLines() throws {
        let load = try EventLine.parse(#"load(page Int = 1) -> posts = try await LemmyAPI.posts(page: page) "loads one page""#)
        XCTAssertEqual(load.verb, "load")
        XCTAssertEqual(load.params.map(\.name), ["page"])
        XCTAssertEqual(load.params[0].defaultValue, "1")
        XCTAssertEqual(load.write, .replace("posts"))
        XCTAssertEqual(load.expression, "LemmyAPI.posts(page: page)", "the agent adds try await itself")
        XCTAssertEqual(load.doc, "loads one page")
        XCTAssertEqual(load.typeName, "Load")
        let more = try EventLine.parse("more(page: Int) +> posts = API.page(page, filter: \"a, b\")")
        XCTAssertEqual(more.write, .append("posts"))
        XCTAssertEqual(more.expression, "API.page(page, filter: \"a, b\")")
        let vote = try EventLine.parse("vote(post Post, up Bool) = API.vote(post.id, up: up)")
        XCTAssertEqual(vote.write, .none)
        XCTAssertEqual(vote.params.map(\.type.description), ["Post", "Bool"])
        let refresh = try EventLine.parse(#"refresh -> posts "the first page, newest first""#)
        XCTAssertNil(refresh.expression, "with no call, the host's model writes the work")
        XCTAssertEqual(refresh.params, [])
    }

    func testEventLinesThatAreRefusedSayWhy() {
        let refused: [(String, String)] = [
            ("Load(page Int)", "lowerCamelCase"),
            ("set(value Int)", "the service's own"),
            ("load(ticket UUID)", "uses that name itself"),
            ("load(page Int, page Int)", "named twice"),
            ("load(page Int) -> ", "names the state field"),
            ("load(page Int) => posts", "not `=> posts`"),
            ("load(page Int -> posts", "never closed"),
        ]
        for (line, reason) in refused {
            XCTAssertThrowsError(try EventLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
            }
        }
    }

    func testRelayLines() throws {
        XCTAssertEqual(try RelayLine.parse("feed: FeedService"), Relay(name: "feed", type: "FeedService"))
        XCTAssertEqual(try RelayLine.parse("Feed"), Relay(name: "feed", type: "FeedService"))
        XCTAssertEqual(try RelayLine.parse("posts Feed"), Relay(name: "posts", type: "FeedService"))
        XCTAssertEqual(try RelayLine.parse("URLCache"), Relay(name: "urlCache", type: "URLCacheService"))
        XCTAssertThrowsError(try RelayLine.parse("feed: feedService"))
    }

    func testShowLines() throws {
        let items = try ShowLine.parse("items = feed.state.posts")
        XCTAssertEqual(items.role, "items")
        XCTAssertEqual(items.expression, "feed.state.posts")
        let title = try ShowLine.parse(#"title = "Feed""#)
        XCTAssertTrue(title.isLiteral)
        XCTAssertEqual(title.literal, "Feed")
        let row = try ShowLine.parse(#""Appearance/Theme" = config.state.appearance"#)
        XCTAssertEqual(row.key, .label(section: "Appearance", text: "Theme"))
        let plain = try ShowLine.parse(#""Show tips" = config.state.showsTips == true"#)
        XCTAssertEqual(plain.key, .label(section: nil, text: "Show tips"))
        XCTAssertEqual(plain.expression, "config.state.showsTips == true", "only the first `=` splits")
        XCTAssertThrowsError(try ShowLine.parse("items feed.state.posts"))
        XCTAssertThrowsError(try ShowLine.parse("Items = x")) { XCTAssertTrue("\($0)".contains("not a role")) }
    }

    func testActionLines() throws {
        let refresh = try ActionLine.parse("refresh = try await feed.load(page: 1)")
        XCTAssertEqual(refresh.name, "refresh")
        XCTAssertEqual(refresh.label, "Refresh")
        let compose = try ActionLine.parse(#"compose "New Post" square.and.pencil = modals.sheet { Write() }; feed.set(.clear)"#)
        XCTAssertEqual(compose.title, "New Post")
        XCTAssertEqual(compose.symbol, "square.and.pencil")
        XCTAssertEqual(compose.statements, ["modals.sheet { Write() }", "feed.set(.clear)"])
        let delete = try ActionLine.parse("deletePost(post Post, reason String = \"spam\") = try await feed.delete(post)")
        XCTAssertEqual(delete.params.map(\.name), ["post", "reason"])
        XCTAssertTrue(delete.isDestructive)
        XCTAssertEqual(delete.label, "Delete Post")
        XCTAssertThrowsError(try ActionLine.parse("refresh feed.load()"))
        XCTAssertThrowsError(try ActionLine.parse(#"share "Share" Square = x"#)) { XCTAssertTrue("\($0)".contains("SF Symbol")) }
    }

    func testViewLines() throws {
        let row = try ViewLine.parse(#"row(post Post, vote (Bool) -> Void, onShare: () -> Void) "title, author and score""#)
        XCTAssertEqual(row.role, "row")
        XCTAssertEqual(row.roleName, "Row")
        XCTAssertEqual(row.values.map(\.name), ["post"])
        XCTAssertEqual(row.closures.map(\.name), ["vote", "onShare"])
        XCTAssertEqual(row.description, "title, author and score")
        XCTAssertEqual(ComponentSpec.closureInputs("(Bool) -> Void"), ["Bool"])
        XCTAssertEqual(ComponentSpec.closureInputs("() -> Void"), [])
        XCTAssertNil(try ViewLine.parse("header(count Int)").description)
        XCTAssertThrowsError(try ViewLine.parse("row(post)")) { XCTAssertTrue("\($0)".contains("needs a name and a type")) }
    }

    func testDestinationLines() throws {
        let feed = try DestinationLine.parse(#"feed: Feed "Feed" house"#)
        XCTAssertEqual(feed, Destination(name: "feed", view: "Feed()", viewType: "Feed", title: "Feed", symbol: "house", detail: nil, detailType: nil))
        let inbox = try DestinationLine.parse(#"inbox: Inbox(filter: .unread) "Inbox" tray.full | Message"#)
        XCTAssertEqual(inbox.view, "Inbox(filter: .unread)")
        XCTAssertEqual(inbox.detail, "Message()")
        XCTAssertEqual(inbox.symbol, "tray.full")
        for (line, reason) in [("feed Feed \"Feed\" house", "is `name: View"), (#"feed: Feed Feed house"#, "in quotes"), (#"feed: Feed "Feed""#, "SF Symbol")] {
            XCTAssertThrowsError(try DestinationLine.parse(line), line) { XCTAssertTrue("\($0)".contains(reason), "\(line) → \($0)") }
        }
    }

    func testPackageLines() throws {
        let revision = String(repeating: "a1", count: 20)
        let nuke = try PackageLine.parse("https://github.com/kean/Nuke@\(revision) Nuke NukeUI")
        XCTAssertEqual(nuke.requirement, .revision(revision))
        XCTAssertEqual(nuke.products, ["Nuke", "NukeUI"])
        XCTAssertEqual(nuke.identity, "Nuke")
        XCTAssertEqual(try PackageLine.parse("https://github.com/apple/swift-collections.git@1.1.4 Collections").identity, "swift-collections")
        XCTAssertThrowsError(try PackageLine.parse("https://github.com/kean/Nuke@main Nuke")) { XCTAssertTrue("\($0)".contains("never a branch")) }
        XCTAssertThrowsError(try PackageLine.parse("https://github.com/kean/Nuke@\(revision)")) { XCTAssertTrue("\($0)".contains("name the products")) }
    }

    func testFieldLinesAreTheModelsSyntax() throws {
        let field = try FieldLine.parseField(#"posts [Post] = [] "what the feed shows""#, in: "")
        XCTAssertEqual(field.type, .array(.named("Post")))
        XCTAssertEqual(field.defaultValue, "[]")
        XCTAssertEqual(field.doc, "what the feed shows")
        XCTAssertEqual(try FieldLine.parseField("selected: string?", in: "").type, .optional(.named("String")))
        XCTAssertThrowsError(try FieldLine.parseField("Selected String", in: ""))
    }

    func testNamesAreSaidAsSwiftSaysThem() {
        XCTAssertEqual(SwiftName.service("Config").type, "ConfigService")
        XCTAssertEqual(SwiftName.service("ConfigService").base, "Config")
        XCTAssertEqual(SwiftName.relayName("FeedService"), "feed")
        XCTAssertEqual(SwiftName.title("markAllRead"), "Mark All Read")
        XCTAssertEqual(SwiftName.member("default"), "`default`")
        XCTAssertEqual(SwiftName.member("open"), "open", "a contextual keyword is a name like any other")
    }

    /// `_ name Type` is taken as `name Type` (Margin, 2026-11-01).
    func testAnEventParameterMayStartWithAnUnderscore() throws {
        let event = try EventLine.parse("create(_ body NewPost) -> post = API.create(body)")
        XCTAssertEqual(event.params.map(\.name), ["body"])
    }
}
