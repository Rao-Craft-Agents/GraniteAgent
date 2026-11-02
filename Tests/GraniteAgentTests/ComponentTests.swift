import Foundation
import XCTest
@testable import GraniteAgent

/// `make: component`: a page in the component shape, laid out from what it shows and does, bound to its services'
/// real fields, with its subviews from the model when a line describes them and from their values' fields otherwise.
final class ComponentTests: XCTestCase {
    /// A recipe app with its model type and its recipes service.
    private func app() async throws -> URL {
        let folder = try Fixture.folder()
        try await Fixture.call(Fixture.project, in: folder)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Shared/Models"), withIntermediateDirectories: true)
        try Fixture.recipe.write(to: folder.appendingPathComponent("Shared/Models/Recipe.swift"), atomically: true, encoding: .utf8)
        try await Fixture.call(Fixture.recipesService, in: folder)
        return folder
    }

    private func read(_ folder: URL, _ path: String) throws -> String {
        try String(contentsOf: folder.appendingPathComponent(path), encoding: .utf8)
    }

    func testAListPageIsTheComponentShapeWithEveryStateDrawn() async throws {
        let folder = try await app()
        let result = try await Fixture.call(Fixture.recipeList, in: folder)
        XCTAssertEqual(Set(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent }),
                       ["RecipeList.swift", "RecipeList+Center.swift", "RecipeList+View.swift", "RecipeList+Actions.swift", "RecipeList.RowView.swift", "RelayClock.swift"])
        let component = try read(folder, "Components/RecipeList/RecipeList.swift")
        XCTAssertTrue(component.contains("struct RecipeList: GraniteComponent {\n    @Command var center: Center\n\n    @Relay var recipes: RecipesService"))
        XCTAssertTrue(component.contains("RelayClock([RelayClock.on(RecipesService.self)])"), "its selection is bound to the service")
        let view = try read(folder, "Components/RecipeList/RecipeList+View.swift")
        for piece in ["extension RecipeList: View {", "ForEach(recipes.state.recipes) { recipe in", "RecipeListRowView(recipe: recipe)",
                      ".onTapGesture { recipes.set(.favorite(recipe.id)) }", ".accessibilityAddTraits(.isButton)", "Button(\"Favorite\", systemImage: \"star\") { Task { try? await favor(recipe: recipe) } }",
                      ".swipeActions {", "if recipe.id == recipes.state.recipes.last?.id, recipes.state.loading == nil { Task { try? await more() } }", ".refreshable { try? await refresh() }",
                      ".keyboardShortcut(\"r\")", ".task(id: isReady) {", "guard isReady, recipes.state.recipes.isEmpty else { return }",
                      "ContentUnavailableView(\"No recipes yet\", systemImage: \"tray\")", "if recipes.state.loading != nil {",
                      "if let message = recipes.state.lastError {", "Button(\"Try Again\")", ".navigationTitle(\"Recipes\")",
                      "private var isReady: Bool { recipes.isLoaded }"] {
            XCTAssertTrue(view.contains(piece), piece)
        }
        let actions = try read(folder, "Components/RecipeList/RecipeList+Actions.swift")
        XCTAssertTrue(actions.contains("func refresh() async throws {\n        try await recipes.load(page: 1)\n    }"))
        let row = try read(folder, "Components/RecipeList/Views/RecipeList.RowView.swift")
        for piece in ["struct RecipeListRowView: View {", "let recipe: Recipe", "AsyncImage(url: recipe.photo)", "Text(recipe.title)", "if let summary = recipe.summary {",
                      "Label(recipe.minutes.formatted(), systemImage: \"clock\")", "Text(recipe.added, format: .relative(presentation: .named))",
                      ".accessibilityHidden(true)", "#Preview {\n    RecipeListRowView(recipe: Recipe.preview)"] {
            XCTAssertTrue(row.contains(piece), piece)
        }
    }

    func testSettingsChooseAControlByTheFieldsTypeAndShowWhatTheyCannotWrite() async throws {
        let folder = try await app()
        try await Fixture.call(Fixture.settings, in: folder)
        let view = try read(folder, "Components/Settings/Settings+View.swift")
        XCTAssertTrue(view.contains("Section(\"Appearance\") {\n                Picker(\"Theme\", selection: config.binding(\\.appearance) { .appearance($0) }) {"))
        XCTAssertTrue(view.contains("ForEach(AppAppearance.allCases) { option in\n                        Text(option.title).tag(option)"))
        XCTAssertTrue(view.contains("LabeledContent(\"Launches\", value: config.state.launches.formatted())"), "launches has no writer of its own: shown, not bound")
        XCTAssertTrue(view.contains("if let value = config.state.lastOpened {"))
        XCTAssertTrue(view.contains("Button(\"Restore Defaults\") { Task { try? await restore() } }"))
        XCTAssertTrue(view.contains(".formStyle(.grouped)"))
    }

    func testAComposePageSendsAndClosesOrCancels() async throws {
        let folder = try await app()
        try await Fixture.call(Fixture.compose, in: folder)
        XCTAssertTrue(try read(folder, "Components/NewRecipe/NewRecipe.swift").contains("@Environment(\\.dismiss) var dismiss"))
        let center = try read(folder, "Components/NewRecipe/NewRecipe+Center.swift")
        XCTAssertTrue(center.contains("var title: String = \"\"") && center.contains("var minutes: Int = 30"))
        let view = try read(folder, "Components/NewRecipe/NewRecipe+View.swift")
        XCTAssertTrue(view.contains("TextField(\"Title\", text: center.$state.binding.title)"))
        XCTAssertTrue(view.contains("TextField(\"Notes\", text: center.$state.binding.notes, axis: .vertical)"))
        XCTAssertTrue(view.contains("Stepper(value: center.$state.binding.minutes) {"))
        XCTAssertTrue(view.contains("ToolbarItem(placement: .cancellationAction) {\n                Button(\"Cancel\") { dismiss() }"))
        XCTAssertTrue(view.contains("Task { if (try? await submit()) != nil { dismiss() } }"))
        XCTAssertTrue(view.contains(".disabled(recipes.state.loading != nil || state.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)"))
    }

    func testASearchKeepsItsQueryAndSearchesOnceTheTypingSettles() async throws {
        let folder = try await app()
        try await Fixture.call(Fixture.search, in: folder)
        XCTAssertTrue(try read(folder, "Components/RecipeSearch/RecipeSearch+Center.swift").contains("var query: String = \"\""))
        let view = try read(folder, "Components/RecipeSearch/RecipeSearch+View.swift")
        XCTAssertTrue(view.contains(".searchable(text: center.$state.binding.query, prompt: Text(\"Search\"))"))
        XCTAssertTrue(view.contains(".onSubmit(of: .search) { Task { try? await search(text: state.query) } }"))
        XCTAssertTrue(view.contains("try? await Task.sleep(nanoseconds: 300_000_000)"))
        XCTAssertTrue(view.contains("ContentUnavailableView.search(text: state.query)"))
    }

    func testADetailPageShowsItsInputAndTheModelWritesTheViewItsLineDescribes() async throws {
        let folder = try await app()
        let model = FakeHostModel(bodies: ["VStack(alignment: .leading) {\n    Text(recipe.title).font(.title)\n}"])
        let result = try await Fixture.call(Fixture.detail, in: folder, model: model)
        XCTAssertEqual(model.asked.count, 1)
        XCTAssertTrue(model.asked[0].user.contains("View: struct RecipeDetailHeaderView: View { let recipe: Recipe }"))
        XCTAssertTrue(model.asked[0].user.contains("Recipe: id String, title String, summary String?, minutes Int, photo URL?, added Date"), "the value's fields")
        XCTAssertTrue(model.asked[0].user.contains("What it shows: the photo large, the title and how long it takes"))
        XCTAssertTrue(result.types.contains("RecipeDetailHeaderView"))
        let component = try read(folder, "Components/RecipeDetail/RecipeDetail.swift")
        XCTAssertTrue(component.contains("let recipe: Recipe\n\n    init(recipe: Recipe) {\n        self.recipe = recipe\n    }"))
        let view = try read(folder, "Components/RecipeDetail/RecipeDetail+View.swift")
        XCTAssertTrue(view.contains("RecipeDetailHeaderView(recipe: recipe)"))
        XCTAssertFalse(view.contains("let recipe = recipe"))
        XCTAssertTrue(view.contains(".navigationTitle(recipe.title)"))
        XCTAssertTrue(view.contains("ToolbarItemGroup(placement: .secondaryAction) {"))
        XCTAssertTrue(try read(folder, "Components/RecipeDetail/Views/RecipeDetail.HeaderView.swift").contains("Text(recipe.title).font(.title)"))
    }

    func testWithoutAModelADescribedViewIsMadeFromItsFields() async throws {
        let folder = try await app()
        let result = try await Fixture.call(Fixture.detail, in: folder)
        XCTAssertTrue(result.notes.contains { $0.contains("RecipeDetailHeaderView is made from its values' fields") })
        let header = try read(folder, "Components/RecipeDetail/Views/RecipeDetail.HeaderView.swift")
        XCTAssertTrue(header.contains("Text(recipe.title)"))
    }

    func testTabsAThreePaneAndABlankPage() async throws {
        let folder = try await app()
        try await Fixture.call(Fixture.recipeList, in: folder)
        try await Fixture.call(Fixture.grid, in: folder)
        try await Fixture.call(Fixture.tabs, in: folder)
        let tabs = try read(folder, "Components/Library/Library+View.swift")
        XCTAssertTrue(tabs.contains("Picker(\"Section\", selection: center.$state.binding.tab) {"))
        XCTAssertTrue(tabs.contains("switch state.tab {\n                case 0:\n                    RecipeList()\n                default:\n                    RecipeGrid()"))
        try await Fixture.call(Fixture.browser, in: folder)
        let browser = try read(folder, "Components/RecipeBrowser/RecipeBrowser+View.swift")
        XCTAssertTrue(browser.contains("List(recipes.state.recipes, selection: recipes.binding(\\.favorite) { .favorite($0) }) { recipe in"))
        XCTAssertTrue(browser.contains("if let recipe = recipes.state.recipes.first(where: { $0.id == recipes.state.favorite }) {"))
        XCTAssertTrue(browser.contains("RecipeBrowserContentView(recipe: recipe)"))
        let grid = try read(folder, "Components/RecipeGrid/Views/RecipeGrid.CellView.swift")
        XCTAssertTrue(grid.contains(".background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))"))
        let model = FakeHostModel(bodies: ["List(recipes.state.recipes) { recipe in\n    Text(recipe.title)\n}"])
        try await Fixture.call(Fixture.today, in: folder, model: model)
        XCTAssertTrue(model.asked[0].user.contains("Relay recipes: RecipesService (state: recipes [Recipe]"))
        XCTAssertTrue(try read(folder, "Components/Today/Today+View.swift").contains("private var content: some View {\n        List(recipes.state.recipes) { recipe in"))
    }

    /// A blank page that shows a view the app has is asked for with that view's shape, the shapes it names in turn,
    /// and the page's own functions as written (Hearth, 2026-11-01: a body written without them read `target.post`,
    /// passed a String for a vote, and declared the page's actions a second time).
    func testABlankPageIsAskedForWithTheShapesOfTheViewsItShows() async throws {
        let folder = try await app()
        try """
        import SwiftUI

        enum DishTarget {
            case dish(Recipe)
            case cook(String)
        }

        struct DishActions {
            var favor: ((DishTarget) -> Void)?
            var refresh: (() async -> Void)?
        }

        struct DishFeed: View {
            let dishes: [Recipe]
            init(title: Text? = nil,
                 dishes: [Recipe],
                 actions: DishActions = DishActions()) {
                self.dishes = dishes
            }
            var body: some View { Text("") }
        }
        """.write(to: folder.appendingPathComponent("Shared/DishFeed.swift"), atomically: true, encoding: .utf8)
        let model = FakeHostModel(bodies: ["DishFeed(dishes: dishes)", "KitchenDishFeedView(dishes: recipes.state.recipes)"])
        let input = GraniteAppAgent.Input(make: .component, type: "Kitchen", relays: ["recipes: RecipesService"], layout: .blank,
                                          actions: ["refresh = try await recipes.load(page: 1)"],
                                          views: ["dishFeedView(dishes [Recipe]) \"the app's DishFeed over the dishes\""],
                                          notes: "shows the app's DishFeed over the recipes, refreshing on pull")
        try await Fixture.call(input, in: folder, model: model)
        XCTAssertTrue(model.asked[0].user.contains("struct KitchenDishFeedView: View") && model.asked[0].user.contains("case dish(Recipe)"),
                      "a subview is named once, and asked for with the shapes it names: \(model.asked[0].user)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Components/Kitchen/Views/Kitchen.DishFeedView.swift").path))
        let user = model.asked[1].user
        for part in ["func refresh() async throws", "never declare them again", "struct DishFeed: View",
                     "init(title: Text? = nil, dishes: [Recipe], actions: DishActions = DishActions())",
                     "struct DishActions", "var favor: ((DishTarget) -> Void)?", "enum DishTarget", "case dish(Recipe)"] {
            XCTAssertTrue(user.contains(part), "\(part) in \(user)")
        }
    }

    /// A blank page whose body the call gives is written as given, with no model; a body that does not parse is refused.
    func testABlankPageTakesItsBodyFromTheCall() async throws {
        let folder = try await app()
        let input = GraniteAppAgent.Input(make: .component, type: "Shelf", relays: ["recipes: RecipesService"], layout: .blank,
                                          actions: ["refresh = try await recipes.load(page: 1)"],
                                          body: "List(recipes.state.recipes) { recipe in\n    Text(recipe.title)\n}\n.refreshable { try? await refresh() }")
        try await Fixture.call(input, in: folder)
        let view = try read(folder, "Components/Shelf/Shelf+View.swift")
        XCTAssertTrue(view.contains("List(recipes.state.recipes) { recipe in") && view.contains(".refreshable { try? await refresh() }"), view)
        var broken = input
        broken.type = "Pantry"
        broken.body = "List(recipes.state.recipes) { recipe in"
        do {
            try await Fixture.call(broken, in: folder)
            XCTFail("a body that does not parse is refused")
        } catch {
            XCTAssertTrue("\(error)".contains("the page's `body` does not parse"), "\(error)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Components/Pantry").path))
    }

    /// A body that makes a view no one has, or awaits work the page does not have, is asked for again with the reason
    /// (Margin, 2026-11-01: `Spinner()` and `await refresh()` on a page without one).
    func testABodyWithNamesNoOneHasIsAskedForAgain() async throws {
        let folder = try await app()
        let model = FakeHostModel(bodies: ["VStack {\n    Spinner()\n}\n.task { try? await refresh() }",
                                           "VStack {\n    ProgressView()\n    KitchenNoteView(text: \"Hi\")\n}\n.task { try? await load() }"])
        let input = GraniteAppAgent.Input(make: .component, type: "Kitchen", relays: ["recipes: RecipesService"], layout: .blank,
                                          actions: ["load = try await recipes.load(page: 1)"], views: ["note(text String)"], notes: "a kitchen page")
        try await Fixture.call(input, in: folder, model: model)
        XCTAssertEqual(model.asked.count, 2, "asked again once")
        let again = model.asked[1].user
        XCTAssertTrue(again.contains("`Spinner` is not a view SwiftUI or this app has") && again.contains("`refresh()` is not one of the page's actions (it has `load()`)"), again)
        XCTAssertTrue(try read(folder, "Components/Kitchen/Kitchen+View.swift").contains("ProgressView()"))
    }

    /// What a page reaches through a relay is its service's: an entry it has, or its state through `.state` (Margin).
    func testAPageReachesOnlyWhatItsServiceHas() async throws {
        let folder = try await app()
        let input = GraniteAppAgent.Input(make: .component, type: "Shelf", relays: ["recipes: RecipesService"], layout: .list,
                                          shows: ["items = recipes.state.recipes", "title = \"Shelf\""],
                                          actions: ["refresh = try await recipes.reload()", "clear = recipes.favorite = nil"])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the page is refused")
        } catch {
            let text = "\(error)"
            XCTAssertTrue(text.contains("`refresh`: RecipesService has no `reload`: its work is"), text)
            XCTAssertTrue(text.contains("`clear`: `recipes.favorite` is RecipesService's state: read it as `recipes.state.favorite`"), text)
        }
    }

    /// A list of a service's field that no action loads is refused, naming the work that would (Margin, 2026-11-01).
    func testAListNothingLoadsIsRefused() async throws {
        let folder = try await app()
        let input = GraniteAppAgent.Input(make: .component, type: "Shelf", relays: ["recipes: RecipesService"], layout: .list,
                                          shows: ["items = recipes.state.recipes", "title = \"Shelf\""])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the page is refused")
        } catch {
            XCTAssertTrue("\(error)".contains("`recipes.state.recipes` is loaded by nothing on this page: add a `refresh` action that loads it, from RecipesService's work (`func load(page: Int)"), "\(error)")
        }
        var loaded = input
        loaded.actions = ["refresh = try await recipes.load(page: 1)"]
        try await Fixture.call(loaded, in: folder)
    }

    /// A page named as a local package's type is refused, since it would shadow it (Margin's `PostPage`).
    func testAPageNamedAsAPackagesTypeIsRefused() async throws {
        let folder = try await app()
        let sources = folder.appendingPathComponent("Packages/ShelfKit/Sources/ShelfKit")
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try "// swift-tools-version: 5.9\n".write(to: folder.appendingPathComponent("Packages/ShelfKit/Package.swift"), atomically: true, encoding: .utf8)
        try "public struct ShelfPage: Codable {\n    public var items: [String]\n}\n".write(to: sources.appendingPathComponent("ShelfPage.swift"), atomically: true, encoding: .utf8)
        let input = GraniteAppAgent.Input(make: .component, type: "ShelfPage", relays: ["recipes: RecipesService"], layout: .list,
                                          shows: ["items = recipes.state.recipes"], actions: ["refresh = try await recipes.load(page: 1)"])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the page is refused")
        } catch {
            XCTAssertTrue("\(error)".contains("`ShelfPage` is ShelfKit's type: name the page something else, like `ShelfDetail`"), "\(error)")
        }
    }

    func testAPageItCannotDrawIsRefusedWithEveryReason() async throws {
        let folder = try await app()
        let input = GraniteAppAgent.Input(make: .component, type: "FeedComponent", relays: ["feed: FeedService"], layout: .threePane,
                                          shows: ["title = \"Feed\""], actions: ["view = feed.load()", "refresh = x", "refresh = y"])
        do {
            try await Fixture.call(input, in: folder)
            XCTFail("the page is refused")
        } catch {
            let text = "\(error)"
            for reason in ["`FeedService` is not in the project", "add `items = …`", "add `selection = …`", "`view` is the page's own", "`refresh` is named twice"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
        do {
            try await Fixture.call(GraniteAppAgent.Input(make: .component, type: "Today", layout: .blank), in: folder)
            XCTFail("a blank page needs the model")
        } catch {
            XCTAssertTrue("\(error)".contains("comes from `body` or the host's model"))
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Components/Feed").path))
    }

    func testAClosureOfAViewIsFilledByTheActionOfItsName() throws {
        let spec = ComponentSpec(type: "Feed", layout: .list, relays: [], fields: [], shows: [],
                                 actions: [try ActionLine.parse("vote(post Post, up Bool) = try await feed.vote(post: post, up: up)")],
                                 views: [try ViewLine.parse("row(post Post, vote (Bool) -> Void, share () -> Void)")], index: ProjectIndex())
        let row = spec.views[0]
        XCTAssertEqual(spec.instance(row, item: "post", itemType: "Post"),
                       "FeedRowView(post: post, vote: { up in Task { try? await vote(post: post, up: up) } })",
                       "a closure no action fills is left out, and its control hides")
        XCTAssertEqual(ComponentEmitter.writingOwnState("state.query = \"\"; feed.state.x == 1"), "_state.query.wrappedValue = \"\"; feed.state.x == 1")
    }

    /// A page over standard values (a `[String]` of tags) draws them by `id: \.self`: `String` is not Identifiable.
    func testAListOfStandardValuesIsDrawnBySelf() async throws {
        let folder = try await app()
        try await Fixture.call(GraniteAppAgent.Input(make: .service, type: "Tags", state: ["tags [String] = []"]), in: folder)
        try await Fixture.call(GraniteAppAgent.Input(make: .component, type: "TagList", relays: ["tags: TagsService"], layout: .list,
                                                     shows: ["items = tags.state.tags", #"title = "Tags""#]), in: folder)
        let view = try read(folder, "Components/TagList/TagList+View.swift")
        XCTAssertTrue(view.contains("ForEach(tags.state.tags, id: \\.self) {"), view)
        XCTAssertFalse(view.contains("ForEach(tags.state.tags) {"), view)
    }

    /// A type a local package declares is imported wherever a written file names it: a row drawn from it, a service's
    /// Ops test whose sample is one.
    func testAPackagesTypeIsImportedWhereverAFileNamesIt() async throws {
        let folder = try await app()
        let kit = folder.appendingPathComponent("Packages/TrailKit")
        try FileManager.default.createDirectory(at: kit.appendingPathComponent("Sources/TrailKit"), withIntermediateDirectories: true)
        try "// swift-tools-version:6.0\nimport PackageDescription\nlet package = Package(name: \"TrailKit\", targets: [.target(name: \"TrailKit\")])\n"
            .write(to: kit.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try "public struct Trail: Codable, Hashable, Identifiable, Sendable {\n    public var id: String\n    public var name: String\n    public static let preview = Trail(id: \"t\", name: \"Ridge\")\n}\n"
            .write(to: kit.appendingPathComponent("Sources/TrailKit/Trail.swift"), atomically: true, encoding: .utf8)
        try await Fixture.call(GraniteAppAgent.Input(make: .service, type: "Trails", state: ["trails [Trail] = []"]), in: folder)
        try await Fixture.call(GraniteAppAgent.Input(make: .component, type: "TrailList", relays: ["trails: TrailsService"], layout: .list,
                                                     shows: ["items = trails.state.trails", #"title = "Trails""#]), in: folder)
        for path in ["Services/TrailsService/TrailsService+Center.swift", "Tests/TrailsOpsTests.swift", "Components/TrailList/Views/TrailList.RowView.swift"] {
            let text = try read(folder, path)
            XCTAssertEqual(text.components(separatedBy: "import TrailKit\n").count - 1, 1, "\(path) imports TrailKit once:\n\(text.prefix(300))")
        }
    }
}
