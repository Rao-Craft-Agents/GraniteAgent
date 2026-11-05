import Foundation
@testable import GraniteAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("granite-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// One call, as the host makes it, into `folder`.
    @discardableResult
    static func call(_ input: GraniteAppAgent.Input, in folder: URL, model: FakeHostModel? = nil) async throws -> GraniteResult {
        var input = input
        input.directory = folder.path
        return try await GraniteAppAgent.write(input, model: model, note: { _ in }, yield: { _ in })
    }

    /// A recipe app's own value type, as the `models` agent writes one, with the call the app's work makes.
    static let recipe = """
        import Foundation

        /// A dish someone saved.
        struct Recipe: Codable, Hashable, Identifiable, Sendable {
            var id: String
            var title: String
            var summary: String?
            var minutes: Int
            var photo: URL?
            var added: Date

            init(id: String, title: String, summary: String? = nil, minutes: Int = 30, photo: URL? = nil, added: Date) {
                self.id = id
                self.title = title
                self.summary = summary
                self.minutes = minutes
                self.photo = photo
                self.added = added
            }
        }

        extension Recipe {
            /// A recipe to preview and test with.
            static let preview: Recipe = Recipe(id: "recipe-1", title: "Sample title", summary: "Sample summary", minutes: 30, added: Date(timeIntervalSince1970: 1_767_225_600))

            /// One page of recipes, as the app's API would answer it.
            static func page(_ page: Int) async throws -> [Recipe] {
                (0..<10).map { index in
                    Recipe(id: "\\(page)-\\(index)", title: "Recipe \\(page * 10 + index)", minutes: 10 + index, added: Date(timeIntervalSince1970: Double(page * 10 + index)))
                }
            }
        }

        """

    static let project = GraniteAppAgent.Input(make: .project, name: "Recipes", bundleId: "com.example.recipes")

    static let recipesService = GraniteAppAgent.Input(
        make: .service, type: "Recipes",
        state: ["recipes [Recipe] = []", #"favorite String? "the recipe starred last""#, "page Int = 1"],
        events: [#"load(page Int) -> recipes = Recipe.page(page) "loads one page""#, "more(page Int) +> recipes = Recipe.page(page)"],
        persist: true)

    static let recipeList = GraniteAppAgent.Input(
        make: .component, type: "RecipeList", relays: ["recipes: RecipesService"], layout: .list,
        shows: ["items = recipes.state.recipes", #"title = "Recipes""#, #"empty = "No recipes yet""#, "selection = recipes.state.favorite"],
        actions: ["refresh = try await recipes.load(page: 1)", "more = try await recipes.more(page: recipes.state.recipes.count / 10 + 1)",
                  #"favor(recipe Recipe) "Favorite" star = recipes.set(.favorite(recipe.id))"#])

    static let search = GraniteAppAgent.Input(
        make: .component, type: "RecipeSearch", relays: ["recipes: RecipesService"], layout: .search,
        shows: ["items = recipes.state.recipes", #"title = "Search""#, #"empty = "Find a recipe by its name""#],
        actions: ["search(text String) = try await recipes.load(page: 1)"])

    static let navigation = GraniteAppAgent.Input(
        make: .navigation,
        destinations: [#"recipes: RecipeList "Recipes" book"#, #"search: RecipeSearch "Search" magnifyingglass"#, #"settings: Settings "Settings" gearshape"#],
        style: .adaptive)

    static let modals = GraniteAppAgent.Input(make: .modals)

    static let kit = GraniteAppAgent.Input(make: .package, name: "RecipeKit")

    static let pantry = GraniteAppAgent.Input(
        make: .service, type: "Pantry", into: "Packages/RecipeKit",
        state: ["items [String] = []", "checked [String: Bool] = [:]"],
        events: [#"restock(item String) +> items "adds what ran out to the list""#, "empty() -> items = []"],
        notes: "A pantry list: what to buy next.")

    static let grid = GraniteAppAgent.Input(
        make: .component, type: "RecipeGrid", relays: ["recipes: RecipesService"], layout: .grid,
        shows: ["items = recipes.state.recipes", #"title = "Gallery""#],
        actions: ["refresh = try await recipes.load(page: 1)", "open(recipe Recipe) = recipes.set(.favorite(recipe.id))"])

    static let detail = GraniteAppAgent.Input(
        make: .component, type: "RecipeDetail", state: ["let recipe Recipe"], relays: ["recipes: RecipesService"], layout: .detail,
        shows: ["item = recipe", "title = recipe.title"],
        actions: [#"favor(recipe Recipe) "Favorite" star = recipes.set(.favorite(recipe.id))"#,
                  "rate(recipe Recipe, stars Int) = recipes.set(.favorite(recipe.id))",
                  "share(recipe Recipe) = recipes.set(.favorite(recipe.id))"],
        views: [#"header(recipe Recipe, rate (Int) -> Void, share () -> Void) "the photo large, the title and how long it takes""#])

    static let compose = GraniteAppAgent.Input(
        make: .component, type: "NewRecipe", state: [#"title String = """#, #"notes String = """#, "minutes Int = 30"],
        relays: ["recipes: RecipesService"], layout: .compose,
        shows: [#""Title" = state.title"#, #""Notes" = state.notes"#, #""Time/Minutes" = state.minutes"#, #"title = "New Recipe""#],
        actions: [#"submit "Save" = try await recipes.load(page: 1)"#])

    static let tabs = GraniteAppAgent.Input(
        make: .component, type: "Library", layout: .tabs,
        shows: [#""Recipes" = RecipeList()"#, #""Gallery" = RecipeGrid()"#, #"title = "Library""#])

    static let browser = GraniteAppAgent.Input(
        make: .component, type: "RecipeBrowser", relays: ["recipes: RecipesService"], layout: .threePane,
        shows: ["items = recipes.state.recipes", "selection = recipes.state.favorite", #"title = "Browse""#],
        actions: ["refresh = try await recipes.load(page: 1)"])

    static let today = GraniteAppAgent.Input(
        make: .component, type: "Today", relays: ["recipes: RecipesService"], layout: .blank, notes: "today's three newest recipes")

    /// What the host's model answers, in the order the calls above ask: a work body that does not parse and then one
    /// that does, a subview's body, a page's body.
    static func model() -> FakeHostModel {
        FakeHostModel(bodies: [
            "return [item",
            "let trimmed = item.trimmingCharacters(in: .whitespaces)\nguard !trimmed.isEmpty else { throw URLError(.badURL) }\nreturn [trimmed]",
            "VStack(alignment: .leading, spacing: 8) {\n    AsyncImage(url: recipe.photo) { image in\n        image.resizable().scaledToFill()\n    } placeholder: {\n        Color.secondary.opacity(0.15)\n    }\n    .frame(height: 220)\n    .clipShape(RoundedRectangle(cornerRadius: 12))\n    .accessibilityHidden(true)\n    Text(recipe.title)\n        .font(.title.bold())\n    Label(\"\\(recipe.minutes) min\", systemImage: \"clock\")\n        .font(.subheadline)\n        .foregroundStyle(.secondary)\n    HStack(spacing: 16) {\n        Button(\"Rate\") { rate(5) }\n        Button(\"Share\") { share() }\n    }\n}",
            "ScrollView {\n    VStack(alignment: .leading, spacing: 12) {\n        Text(\"Today\")\n            .font(.largeTitle.bold())\n        ForEach(recipes.state.recipes.prefix(3)) { recipe in\n            Text(recipe.title)\n                .font(.headline)\n        }\n    }\n    .padding()\n}",
        ])
    }


    static let settings = GraniteAppAgent.Input(

        make: .component, type: "Settings", relays: ["config: ConfigService"], layout: .settings,
        shows: [#""Appearance/Theme" = config.state.appearance"#, #""Usage/Launches" = config.state.launches"#, #""Usage/Last opened" = config.state.lastOpened"#],
        actions: [#"restore "Restore Defaults" = config.set(.reset)"#])
}
