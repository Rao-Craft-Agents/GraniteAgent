//  WHAT: Everything Granite-specific an iOS + macOS app needs, as a Granite agent package: a new project, Granite
//        brought into an existing one, a kit of services, a service in the skill's single-writer shape with its
//        tests, a page laid out from what it shows and does, the app's navigation, and its modals. One call makes
//        one of them, from compact lines a local model writes in one tool call, and answers the files it wrote.
//  IN:   Input: `make` and the lines that make needs (state, events, relays, shows, actions, views, destinations…).
//  OUT:  GraniteResult: every file written or edited, the types, and a sentence for each decision.
//  PIN:  THE AGENT HOLDS THE QUALITY. Every file is made from the lines; the host's model is asked only for what is
//        the app's own (a unit of work no expression says, a subview's body a line describes), and its Swift is
//        parsed before it lands. A call that cannot be honoured is refused with every reason, and nothing is written.
//  PIN:  ONE CALL AT A TIME (`lanes` 1). Calls edit files several makes share (the project file, the root that
//        holds the relays), so a second call waits for the first.

import Foundation
import GraniteAgents

public struct GraniteAppAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// What to make.
        public var make: GraniteMake
        /// The app's or the kit's name: `Recipes`.
        public var name: String?
        /// The app's bundle identifier; `com.example.<name>` when left out.
        public var bundleId: String?
        /// The Apple team the app signs with.
        public var team: String?
        /// The service (`Feed` is `FeedService`) or the page (`Feed`) to make.
        public var type: String?
        /// The folder the files go in, relative to the host's.
        public var into: String?
        /// A service's or a page's fields, one a line, in the models syntax: `posts [Post] = []`.
        public var state: [String]?
        /// A service's work, one a line: `load(page Int) -> posts = API.posts(page: page)`.
        public var events: [String]?
        /// The services a service's work or a page reads: `feed: FeedService`.
        public var relays: [String]?
        /// How a page draws what it shows.
        public var layout: GraniteLayout?
        /// What a page draws: `items = feed.state.posts`, `"Theme" = config.state.appearance`.
        public var shows: [String]?
        /// What a page does: `refresh = try await feed.load(page: 1)`.
        public var actions: [String]?
        /// A page's subviews: `row(post Post) "title, author and score"`.
        public var views: [String]?
        /// A blank page's body as Swift, written as given (parse-checked) instead of asked of the host's model: the
        /// view the app already has, filled from the relays and actions.
        public var body: String?
        /// The app's destinations: `feed: Feed "Feed" house`.
        public var destinations: [String]?
        /// How the app moves between its destinations.
        public var style: GraniteStyle?
        /// The root page; `Home` when left out.
        public var root: String?
        /// Remote packages the app links, pinned: `https://github.com/kean/Nuke@<revision> Nuke NukeUI`.
        public var packages: [String]?
        /// Modules a service's or a page's files import beside Foundation, SwiftUI and Granite.
        public var imports: [String]?
        /// Whether a service's state is kept between launches.
        public var persist: Bool?
        /// What the work or the page is for: what the host's model writes bodies from.
        public var notes: String?
        /// How many times the host's model may answer one body; 3 when left out.
        public var rounds: Int?
        /// The host's folder.
        public var directory: String?

        public init(make: GraniteMake, name: String? = nil, bundleId: String? = nil, team: String? = nil, type: String? = nil,
                    into: String? = nil, state: [String]? = nil, events: [String]? = nil, relays: [String]? = nil,
                    layout: GraniteLayout? = nil, shows: [String]? = nil, actions: [String]? = nil, views: [String]? = nil,
                    body: String? = nil, destinations: [String]? = nil, style: GraniteStyle? = nil, root: String? = nil, packages: [String]? = nil,
                    imports: [String]? = nil, persist: Bool? = nil, notes: String? = nil, rounds: Int? = nil, directory: String? = nil) {
            self.make = make; self.name = name; self.bundleId = bundleId; self.team = team; self.type = type; self.into = into
            self.state = state; self.events = events; self.relays = relays; self.layout = layout; self.shows = shows; self.body = body
            self.actions = actions; self.views = views; self.destinations = destinations; self.style = style; self.root = root
            self.packages = packages; self.imports = imports; self.persist = persist; self.notes = notes; self.rounds = rounds
            self.directory = directory
        }
    }

    public typealias Event = GraniteFrame
    public typealias Output = GraniteResult
    public typealias Compute = Void

    public static let word = "granite"
    public static let summary = "makes and grows an iOS + macOS app on Granite — the Xcode project, Granite linked into an existing one, kits, services with their reducers and tests, pages laid out from what they show, navigation and modals."
    public static let lanes: Int? = 1
    public static let fields = [
        "make": "what to make: project (a new iOS + macOS app), package (a kit of services), link (Granite into an Xcode project this agent did not make), service, component (a page), navigation, modals",
        "name": "the app's or the kit's name, letters and digits, like `Recipes`: project and package",
        "bundleId": "the app's bundle identifier; com.example.<name> when left out: project",
        "team": "the 10-character Apple team id the app signs with: project",
        "type": "the service (`Feed` makes FeedService) or the page (`Feed`) to make",
        "into": "the folder, relative to the project; Services/<Type> or Components/<Type> when left out; a kit's folder (`Packages/RecipeKit`) puts a public service in the kit",
        "state": "fields, one a line, in the models syntax: `posts [Post] = []`, `selected String?`; a page's `let post Post` is an input it is made with",
        "events": "a service's work, one a line: `load(page Int) -> posts = API.posts(page: page) \"loads a page\"`; `+> posts` appends; with no `= call` the host's model writes the work",
        "relays": "the services a service's work calls or a page reads: `feed: FeedService` or `Feed`",
        "layout": "how a page draws: list, grid, detail, form, settings, search, compose, tabs, threePane, blank",
        "shows": "what a page draws: `items = feed.state.posts`, `item = …`, `selection = feed.state.selected`, `title = \"Feed\"`, `empty = \"No posts yet\"`; a row of a form `\"Section/Label\" = config.state.field`",
        "actions": "what a page does: `refresh = try await feed.load(page: 1)`, `more = …`, `open(post Post) = …`, `compose \"New Post\" square.and.pencil = …`",
        "views": "a page's subviews: `row(post Post, vote (Bool) -> Void) \"title, author and score, with a vote\"`; a description is what the host's model writes the body from",
        "destinations": "the app's places, one a line: `feed: Feed \"Feed\" house`; `| Detail` names the view beside it in the split style",
        "style": "how the app moves between destinations: adaptive (tabs on iPhone, a sidebar on iPad and Mac), tabs, sidebar, split",
        "root": "the root page; Home when left out",
        "packages": "remote packages the app links, pinned: `https://github.com/kean/Nuke@<40-hex revision> Nuke NukeUI`",
        "imports": "modules the files import beside Foundation, SwiftUI and Granite; a local package's are found on their own",
        "persist": "whether a service's state is kept between launches",
        "body": "a blank page's body as Swift, written as given: the view the app has, filled from the page's relays and actions (`FeedView(posts: feed.state.posts, actions: …)`)",
        "notes": "what the work or the page is for, in a sentence: what the host's model writes bodies from",
        "rounds": "how many answers the host's model may give one body before the call is refused; 3 when left out",
    ]
    public static let guide = #"""
        Tag granite for an app's architecture on Granite: the project, its services, its pages, how it navigates and its modals. One call makes one thing, and a turn makes only what its request asks for: `project` once, when there is no app yet; services before the pages that read them; navigation once the pages exist. An app it made already has its project, root and boot, so never call `project` or `link` there again. Each call reads the project as it is, so a page binds to a service's real fields; a call it cannot honour is refused with every reason and nothing is written: fix the lines and call again.

        project: {"make": "project", "name": "Recipes", "bundleId": "com.example.recipes"} writes Recipes.xcodeproj (iOS and macOS apps, unit and UI tests, Granite pinned), the root that boots the app, the environment and settings services, and the Home page. `packages` adds pinned remote packages.

        service: {"make": "service", "type": "Recipes", "state": ["recipes [Recipe] = []", "favorite String?"], "events": ["load(page Int) -> recipes = RecipeAPI.page(page) \"loads a page\"", "more(page Int) +> recipes = RecipeAPI.page(page)", "favor(recipe Recipe) = RecipeAPI.favor(recipe.id)"], "persist": true} writes RecipesService. A state line is the models syntax (`name Type = default`, `?` optional). An event is `verb(param Type) -> field = call`: the call is async and throwing (the agent adds try await), `-> field` replaces the field with its result, `+> field` appends a page to a list, and with no `= call` the host's model writes the work from `notes`. `relays` are services the work calls (`catalog: CatalogService`), never one that calls back. A page then calls `try await recipes.load(page: 1)` (it answers the result), writes a field with `recipes.set(.favorite(id))` and binds one with `recipes.binding(\.favorite) { .favorite($0) }`.

        component: {"make": "component", "type": "RecipeList", "layout": "list", "relays": ["recipes: RecipesService"], "shows": ["items = recipes.state.recipes", "title = \"Recipes\"", "empty = \"No recipes yet\""], "actions": ["refresh = try await recipes.load(page: 1)", "more = try await recipes.more(page: 2)", "open(recipe Recipe) = recipes.set(.favorite(recipe.id))", "favor(recipe Recipe) \"Favorite\" star = try await recipes.favor(recipe: recipe)"], "views": ["row(recipe Recipe, favor () -> Void) \"photo, title and minutes, with a heart\""]} writes the page. Layouts: list, grid and search show `items` (search adds `query`); detail shows `item`; threePane shows `items` and `selection`, and a `sidebar`; form, settings and compose show rows `"Section/Label" = recipes.state.field` or `= state.field`, each a control by its type; tabs shows `"Title" = SomeView()` a tab; blank is written by the host's model: a page that shows a view the app already has (a kit's `FeedView(…)`) is `layout: blank` with its relays and actions, and either the body itself in `body` (written as given) or the view and how to fill it named in `notes`. Actions named refresh, more, open, submit and search do what they say; one that takes an item sits in its row's menu; the others are toolbar buttons (`name "Words" sf.symbol = statements`). A view's closure is filled by the action of its name. The page's own state is `state` lines (`query String = ""`); `let recipe Recipe` is an input it is made with.

        navigation: {"make": "navigation", "destinations": ["recipes: RecipeList \"Recipes\" book", "search: RecipeSearch \"Search\" magnifyingglass", "settings: Settings \"Settings\" gearshape"], "style": "adaptive"} writes the destinations, tabs on iPhone and a sidebar on iPad and the Mac, a layout service, routes and Device, and shows them once the app is ready. The pages must exist first.

        modals: {"make": "modals"} writes ModalService and its host: `modals.sheet(id: "compose", detents: [.medium, .large]) { … }`, `modals.alert(…)`, `modals.toast("Saved", style: .success)`, `modals.travel(id: "draft", title: "Draft") { … }` (a panel that stays while you browse), and on the Mac `modals.window(id:title:size:) { … }`.

        package: {"make": "package", "name": "RecipeKit"} writes a kit in Packages/RecipeKit and links it into the app; `make: service` with `"into": "Packages/RecipeKit"` puts a public service in it.

        link: {"make": "link"} in a project this agent did not make links Granite into every app target and adds the root, the boot and settings services and the root page around the app's ContentView.

        Not for an API's client (network), the app's value types (models), its look (design, loom), or menus and entitlements (platform).
        """#

    public static func output(from events: [GraniteFrame]) -> GraniteResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<GraniteFrame, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var input = input
                    if input.directory == nil { input.directory = context.host.directory }
                    let result = try await Self.write(input, model: context.host.model, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The whole call: the lines read, the files made (the host's model asked where a line says to), staged, checked
    /// and written together.
    static func write(_ input: Input, model: (any AgentHostModel)?, note: @escaping @Sendable (String) -> Void,
                      yield: @escaping @Sendable (GraniteFrame) -> Void) async throws -> GraniteResult {
        let workspace = Workspace(directory: input.directory)
        var plan: Plan
        switch input.make {
        case .project: plan = try ProjectMake(input: input, files: workspace.files).plan()
        case .package: plan = try PackageMake(input: input, workspace: workspace).plan()
        case .link: plan = try LinkMake(input: input, workspace: workspace).plan()
        case .service: plan = try await ServiceMake(input: input, workspace: workspace, model: model, note: note, yield: yield).plan()
        case .component: plan = try await ComponentMake(input: input, workspace: workspace, model: model, note: note, yield: yield).plan()
        case .navigation: plan = try NavigationMake(input: input, workspace: workspace).plan()
        case .modals: plan = try ModalsMake(input: input, workspace: workspace).plan()
        }
        if input.make != .project { try ProjectSync.include(&plan, in: workspace) }
        PackageImports.add(to: &plan, index: ProjectIndex(root: workspace.root))
        guard !plan.files.isEmpty else {
            return GraniteResult(path: nil, paths: [], make: input.make.rawValue, types: plan.types, notes: plan.notes)
        }
        note("writing \(plan.files.count) file\(plan.files.count == 1 ? "" : "s") for \(input.make.rawValue)")
        let written = try workspace.files.write(plan.files.map { ($0.url, $0.text) })
        return GraniteResult(path: written.first, paths: written, make: input.make.rawValue, types: plan.types, notes: plan.notes)
    }
}
