import Foundation
import XCTest
@testable import GraniteAgent

/// `make: service`: the skill's single-writer shape, written whole from the lines; the host's model asked only for
/// work no line says how to do; every call it cannot honour refused with every reason, and nothing written.
final class ServiceTests: XCTestCase {
    /// A recipe app with its model type, in a folder of its own.
    private func app() async throws -> URL {
        let folder = try Fixture.folder()
        try await Fixture.call(Fixture.project, in: folder)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Shared/Models"), withIntermediateDirectories: true)
        try Fixture.recipe.write(to: folder.appendingPathComponent("Shared/Models/Recipe.swift"), atomically: true, encoding: .utf8)
        return folder
    }

    private func read(_ folder: URL, _ path: String) throws -> String {
        try String(contentsOf: folder.appendingPathComponent(path), encoding: .utf8)
    }

    func testAServiceIsTheSkillsShape() async throws {
        let folder = try await app()
        let result = try await Fixture.call(Fixture.recipesService, in: folder)
        let base = "Services/RecipesService/"
        XCTAssertEqual(Set(result.paths.map { String($0.dropFirst(folder.path.count + 1)) }),
                       [base + "RecipesService.swift", base + "RecipesService+Center.swift", base + "Reducers/RecipesService.Set.swift",
                        base + "Reducers/RecipesService.Load.swift", base + "Reducers/RecipesService.More.swift", base + "Ops/RecipesOps.swift",
                        "Tests/RecipesOpsTests.swift", "Shared/Utility/AppRoot.swift"])
        let service = try read(folder, base + "RecipesService.swift")
        XCTAssertTrue(service.contains("@Service(.online) var center: Center"))
        XCTAssertTrue(service.contains("static let tickets = GraniteTickets<Reply>()"))
        XCTAssertTrue(service.contains("static let lane = GraniteLane()"))
        XCTAssertTrue(service.contains("onMain { service.center.set.send(Set.Meta(kind: kind)) }"))
        XCTAssertTrue(service.contains("func load(page: Int) async throws -> [Recipe] {"))
        XCTAssertTrue(service.contains("func binding<Value>(_ keyPath: KeyPath<Center.State, Value>"))
        let writer = try read(folder, base + "Reducers/RecipesService.Set.swift")
        for kind in ["case recipes([Recipe])", "case favorite(String?)", "case page(Int)", "case appendRecipes([Recipe])", "case loading(String?)", "case failed(String)", "case clear"] {
            XCTAssertTrue(writer.contains(kind), kind)
        }
        XCTAssertTrue(writer.contains("var thread: DispatchQueue? { .main }"))
        let more = try read(folder, base + "Reducers/RecipesService.More.swift")
        XCTAssertTrue(more.contains("state.loading = \"more\""), "reduce marks the start")
        XCTAssertTrue(more.contains("let service = Live.service(RecipesService.self)"), "its own service, resolved, never stored")
        XCTAssertTrue(more.contains("let value: [Recipe] = try await RecipesService.lane.run { try await Recipe.page(page) }"))
        XCTAssertTrue(more.contains("service.set(.appendRecipes(value))"))
        XCTAssertTrue(more.contains("await RecipesService.tickets.resolve(ticket, with: .recipes(value))"))
        for file in try FileManager.default.contentsOfDirectory(atPath: folder.appendingPathComponent(base + "Reducers").path) {
            let text = try read(folder, base + "Reducers/" + file)
            XCTAssertFalse(text.contains("Self.tickets") || text.contains("Self.lane"), "inside a reducer, Self is the reducer: \(file)")
            XCTAssertFalse(text.contains("@Relay var recipes"), "no stored relay to its own service: \(file)")
        }
        let ops = try read(folder, base + "Ops/RecipesOps.swift")
        XCTAssertTrue(ops.contains("state.recipes.append(contentsOf: value)"))
        let tests = try read(folder, "Tests/RecipesOpsTests.swift")
        XCTAssertTrue(tests.contains("@testable import Recipes"))
        XCTAssertTrue(tests.contains("let value: [Recipe] = [Recipe.preview]"), "a type's preview is its sample")
        XCTAssertTrue(try read(folder, "Shared/Utility/AppRoot.swift").contains("@Relay(.silence) var recipes: RecipesService"))
        XCTAssertTrue(result.notes.contains { $0.contains("lane") })
    }

    func testAPersistedStateReadsOldFilesAndKeepsItsKey() async throws {
        let folder = try await app()
        try await Fixture.call(Fixture.recipesService, in: folder)
        let center = try read(folder, "Services/RecipesService/RecipesService+Center.swift")
        XCTAssertTrue(center.contains("struct State: GraniteState {"))
        XCTAssertTrue(center.contains(#"@Store(persist: "persistence.Recipes.recipes.0001", autoSave: true, preload: true) var state: State"#))
        XCTAssertTrue(center.contains("recipes = (try? container.decodeIfPresent([Recipe].self, forKey: .recipes)) ?? []"))
        XCTAssertFalse(center.contains("case loading"), "what is in flight is never stored")
        // A field added keeps the key; a field whose type changed moves to the next one.
        var added = Fixture.recipesService
        added.state = (added.state ?? []) + ["drafts [String] = []"]
        try await Fixture.call(added, in: folder)
        XCTAssertTrue(try read(folder, "Services/RecipesService/RecipesService+Center.swift").contains("persistence.Recipes.recipes.0001"))
        var changed = added
        changed.state = ["recipes [Recipe] = []", "favorite Int?", "page Int = 1", "drafts [String] = []"]
        try await Fixture.call(changed, in: folder)
        XCTAssertTrue(try read(folder, "Services/RecipesService/RecipesService+Center.swift").contains("persistence.Recipes.recipes.0002"))
        let root = try read(folder, "Shared/Utility/AppRoot.swift")
        XCTAssertEqual(root.components(separatedBy: "var recipes: RecipesService").count, 2, "the root holds one relay, however many calls")
        var fewer = changed
        fewer.events = [#"load(page Int) -> recipes = Recipe.page(page)"#]
        do {
            try await Fixture.call(fewer, in: folder)
            XCTFail("made again with less work, a reducer would be left behind")
        } catch {
            XCTAssertTrue("\(error)".contains("already does `more` (Services/RecipesService/Reducers/RecipesService.More.swift)"), "\(error)")
        }
    }


    func testEveryProblemIsSaidAtOnceAndNothingIsWritten() async throws {
        let folder = try await app()
        let input = GraniteAppAgent.Input(make: .service, type: "Feed",
                                          state: ["posts [Post] = []", "loading Bool", "user User", "score Int"],
                                          events: ["load(page Int) -> missing = API.load(page)", "load(page Int) -> posts = API.load(page)",
                                                   "count() +> score = API.count()", "refresh() -> posts"],
                                          relays: ["FeedService", "NowhereService"])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the call is refused")
        } catch {
            let text = "\(error)"
            for reason in ["needs a default", "the state has no `missing`", "named twice", "not a list", "relay to itself",
                           "`NowhereService` is not in the project", "no model to write the work"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
            XCTAssertFalse(text.contains("`loading`"), "loading is the service's own and is simply kept")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Services/FeedService").path))
    }

    /// A client the app has is called in an event's work, not relayed: told "make it first", a model made an empty
    /// `HearthClientService` to hold `client: HearthClient` (Hearth, 2026-11-01).
    func testARelayToAClientSaysItIsCalledNotRelayed() async throws {
        let folder = try await app()
        try "public struct RecipeClient { public init() {} }\n".write(to: folder.appendingPathComponent("Shared/RecipeClient.swift"), atomically: true, encoding: .utf8)
        let input = GraniteAppAgent.Input(make: .service, type: "Feed", state: ["posts [String] = []"],
                                          events: ["load(page Int) -> posts = API.load(page)"], relays: ["client: RecipeClient"])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the call is refused")
        } catch {
            let text = "\(error)"
            XCTAssertTrue(text.contains("`RecipeClient` is not a service, so it is not relayed"), text)
            XCTAssertFalse(text.contains("make it first"), text)
        }
    }

    /// A call that answers a page envelope is read for the list the field holds (Hearth, 2026-11-01: six reducers
    /// typed `[Post]` around a call answering `PostPage` did not build, and the model fixed each by hand).
    func testAnEnvelopeIsReadForTheListTheFieldHolds() async throws {
        let folder = try await app()
        try """
        public struct ShelfPage: Codable {
            public var recipes: [Recipe]
            public var total: Int
        }

        public enum PantryAPI {
            public static func shelf(
                _ page: Int,
                limit: Int = 20
            ) async throws -> ShelfPage { ShelfPage(recipes: [], total: 0) }
        }
        """.write(to: folder.appendingPathComponent("Shared/PantryAPI.swift"), atomically: true, encoding: .utf8)
        let input = GraniteAppAgent.Input(make: .service, type: "Recipes", state: ["recipes [Recipe] = []", "total Int = 0"],
                                          events: ["load(page Int) -> recipes = PantryAPI.shelf(page)", "more(page Int) +> recipes = PantryAPI.shelf(page)",
                                                   "count(page Int) -> total = PantryAPI.shelf(page).total"])
        let result = try await Fixture.call(input, in: folder)
        for verb in ["Load", "More"] {
            let text = try read(folder, "Services/RecipesService/Reducers/RecipesService.\(verb).swift")
            XCTAssertTrue(text.contains("PantryAPI.shelf(page).recipes"), text)
        }
        let count = try read(folder, "Services/RecipesService/Reducers/RecipesService.Count.swift")
        XCTAssertTrue(count.contains("PantryAPI.shelf(page).total") && !count.contains(".total.total"), "a member already read is kept: \(count)")
        XCTAssertTrue(result.notes.contains { $0.contains("`load` reads `.recipes` of the ShelfPage that `shelf(…)` answers") }, "\(result.notes)")
        XCTAssertNil(ServiceMake.unwrap("RecipeAPI.page(page)", into: "[Recipe]", index: ProjectIndex(root: folder)),
                     "a call that already answers the field's type is kept")
    }

    /// A call whose answer cannot fill the field is refused, with the calls whose answer can (Hearth, 2026-11-01).
    func testACallWhoseAnswerCannotFillTheFieldIsRefused() async throws {
        let folder = try await app()
        try """
        public struct ShelfPage: Codable {
            public var recipes: [Recipe]
            public var total: Int
        }

        public struct Shelves<Item> {}

        public enum PantryAPI {
            public static func shelf(_ page: Int) async throws -> ShelfPage { ShelfPage(recipes: [], total: 0) }
            public static func shelves(from page: Int) -> Shelves<Recipe> { Shelves() }
        }
        """.write(to: folder.appendingPathComponent("Shared/PantryAPI.swift"), atomically: true, encoding: .utf8)
        let input = GraniteAppAgent.Input(make: .service, type: "Recipes", state: ["recipes [Recipe] = []"],
                                          events: ["load(page Int) -> recipes = PantryAPI.shelves(from: page)"])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the call is refused")
        } catch {
            let text = "\(error)"
            XCTAssertTrue(text.contains("`load`: `shelves(…)` answers `Shelves<Recipe>`, and `recipes` holds `[Recipe]`"), text)
            XCTAssertTrue(text.contains("`shelf(…)` answers `ShelfPage`, read for its `.recipes`"), text)
        }
    }

    func testARelayThatWouldLoopIsRefused() async throws {
        let folder = try await app()
        try await Fixture.call(GraniteAppAgent.Input(make: .service, type: "Index", state: ["count Int = 0"],
                                                     events: ["file(title String) -> count = 1"]), in: folder)
        try await Fixture.call(GraniteAppAgent.Input(make: .service, type: "Library", state: ["titles [String] = []"],
                                                     events: ["add(title String) +> titles = index.file(title: title).description.map { _ in title }"],
                                                     relays: ["index: IndexService"]), in: folder)
        let add = try read(folder, "Services/LibraryService/Reducers/LibraryService.Add.swift")
        XCTAssertTrue(add.contains("@Relay var index: IndexService"), "the reducer holds the relay its work names")
        XCTAssertTrue(add.contains("let index = self.index"), "captured before .run")
        do {
            try await Fixture.call(GraniteAppAgent.Input(make: .service, type: "Index", state: ["count Int = 0"],
                                                         events: ["file(title String) -> count = library.titles().count"],
                                                         relays: ["library: LibraryService"]), in: folder)
            XCTFail("a relay back to a service whose reducers reach this one is refused")
        } catch {
            XCTAssertTrue("\(error)".contains("close a loop"), "\(error)")
        }
    }

    func testTheModelWritesWorkNoLineSaysHowToDoAndIsAskedAgainWhenItDoesNotParse() async throws {
        let folder = try await app()
        let model = FakeHostModel(bodies: ["return [item", "return [item.trimmingCharacters(in: .whitespaces)]"])
        let input = GraniteAppAgent.Input(make: .service, type: "Pantry", state: ["items [String] = []"],
                                          events: [#"restock(item String) +> items "adds what ran out""#], notes: "A pantry list.")
        let result = try await Fixture.call(input, in: folder, model: model)
        XCTAssertEqual(model.asked.count, 2, "the first answer did not parse")
        XCTAssertTrue(model.asked[0].user.contains("static func work(item: String) async throws -> [String]"))
        XCTAssertTrue(model.asked[0].user.contains("About the app: A pantry list."))
        XCTAssertTrue(model.asked[0].system.contains("recipe app"), "the worked example is another app's")
        XCTAssertTrue(model.asked[1].user.contains("What was wrong with it"))
        let restock = try read(folder, "Services/PantryService/Reducers/PantryService.Restock.swift")
        XCTAssertTrue(restock.contains("static func work(item: String) async throws -> [String] {\n            return [item.trimmingCharacters(in: .whitespaces)]\n        }"))
        XCTAssertTrue(restock.contains("try await PantryService.lane.run { try await Restock.work(item: item) }"))
        XCTAssertTrue(result.types.contains("PantryService.Restock"))
    }

    func testABodyThatNeverComesRightIsRefused() async throws {
        let folder = try await app()
        let model = FakeHostModel(bodies: ["fatalError(\"later\")"])
        let input = GraniteAppAgent.Input(make: .service, type: "Pantry", state: ["items [String] = []"], events: ["restock(item String) +> items"], rounds: 2)
        do {
            try await Fixture.call(input, in: folder, model: model)
            XCTFail("a body with fatalError is never written")
        } catch {
            XCTAssertTrue("\(error)".contains("did not come out right in 2 rounds"), "\(error)")
        }
        XCTAssertEqual(model.asked.count, 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Services/PantryService").path))
    }

    func testAServiceInAKitIsPublicAndItsRootHoldsIt() async throws {
        let folder = try await app()
        try await Fixture.call(Fixture.kit, in: folder)
        let result = try await Fixture.call(GraniteAppAgent.Input(make: .service, type: "Pantry", into: "Packages/RecipeKit",
                                                                  state: ["items [String] = []"], events: ["empty() -> items = []"]), in: folder)
        let base = "Packages/RecipeKit/Sources/RecipeKit/Services/PantryService/"
        let service = try read(folder, base + "PantryService.swift")
        XCTAssertTrue(service.contains("public struct PantryService: GraniteService {"))
        XCTAssertTrue(service.contains("public func empty() async throws -> [String] {"))
        XCTAssertTrue(try read(folder, base + "PantryService+Center.swift").contains("public var items: [String] = []"))
        XCTAssertTrue(try read(folder, base + "Reducers/PantryService.Empty.swift").contains("RecipeKit") == false)
        XCTAssertTrue(try read(folder, base + "Reducers/PantryService.Empty.swift").contains("try await PantryService.lane.run { [] }"), "a literal needs no try await")
        XCTAssertTrue(try read(folder, "Packages/RecipeKit/Sources/RecipeKit/RecipeKitRoot.swift").contains("@Relay(.silence) public var pantry: PantryService"))
        XCTAssertTrue(try read(folder, "Packages/RecipeKit/Tests/RecipeKitTests/PantryOpsTests.swift").contains("@testable import RecipeKit"))
        XCTAssertFalse(result.paths.contains { $0.hasSuffix("AppRoot.swift") }, "the app's root does not hold a kit's service")
    }
}
