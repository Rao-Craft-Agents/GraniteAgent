# craft-agent/1 · granite

Makes and grows an iOS + macOS app on Granite — the Xcode project, Granite linked into an existing one, kits, services with their reducers and tests, pages laid out from what they show, navigation and modals.

granite's copy of Craft's agent standard (`craft-agent/1`, Craft's `Schema/Agent.md`), written by
`craft agents schema granite` from its record. Everything above **Changes** is written again each time; Changes is
granite's own log.

| File | What it holds |
| --- | --- |
| [`granite.input.schema.json`](granite.input.schema.json) | What it takes, as JSON Schema |
| [`granite.answer.schema.json`](granite.answer.schema.json) | What it answers: `granite-answer/1` with its own kinds |
| [`examples/granite.answer.json`](examples/granite.answer.json) | A real answer, from a regime run |

## What it takes

| Field | Required | What it is |
| --- | --- | --- |
| `make` | yes | what to make: project (a new iOS + macOS app), package (a kit of services), link (Granite into an Xcode project this agent did not make), service, component (a page), navigation, modals |
| `name` | no | the app's or the kit's name, letters and digits, like `Recipes`: project and package |
| `bundleId` | no | the app's bundle identifier; com.example.<name> when left out: project |
| `team` | no | the 10-character Apple team id the app signs with: project |
| `type` | no | the service (`Feed` makes FeedService) or the page (`Feed`) to make |
| `into` | no | the folder, relative to the project; Services/<Type> or Components/<Type> when left out; a kit's folder (`Packages/RecipeKit`) puts a public service in the kit |
| `state` | no | fields, one a line, in the models syntax: `posts [Post] = []`, `selected String?`; a page's `let post Post` is an input it is made with |
| `events` | no | a service's work, one a line: `load(page Int) -> posts = API.posts(page: page) "loads a page"`; `+> posts` appends; with no `= call` the host's model writes the work |
| `relays` | no | the services a service's work calls or a page reads: `feed: FeedService` or `Feed` |
| `layout` | no | how a page draws: list, grid, detail, form, settings, search, compose, tabs, threePane, blank |
| `shows` | no | what a page draws: `items = feed.state.posts`, `item = …`, `selection = feed.state.selected`, `title = "Feed"`, `empty = "No posts yet"`; a row of a form `"Section/Label" = config.state.field` |
| `actions` | no | what a page does: `refresh = try await feed.load(page: 1)`, `more = …`, `open(post Post) = …`, `compose "New Post" square.and.pencil = …` |
| `views` | no | a page's subviews: `row(post Post, vote (Bool) -> Void) "title, author and score, with a vote"`; a closure is an action the view sends up with `bubble`, routed by the page to the action of its name; a description is what the host's model writes the body from |
| `body` | no | a blank page's body as Swift, written as given: the view the app has, filled from the page's relays and actions (`FeedView(posts: feed.state.posts, actions: …)`) |
| `destinations` | no | the app's places, one a line: `feed: Feed "Feed" house`; `\| Detail` names the view beside it in the split style |
| `style` | no | how the app moves between destinations: adaptive (tabs on iPhone, a sidebar on iPad and Mac), tabs, sidebar, split |
| `root` | no | the root page; Home when left out |
| `packages` | no | remote packages the app links, pinned: `https://github.com/kean/Nuke@<40-hex revision> Nuke NukeUI` |
| `imports` | no | modules the files import beside Foundation, SwiftUI and Granite; a local package's are found on their own |
| `persist` | no | whether a service's state is kept between launches |
| `notes` | no | what the work or the page is for, in a sentence: what the host's model writes bodies from |
| `rounds` | no | how many answers the host's model may give one body before the call is refused; 3 when left out |

`directory` is filled by Craft with the project folder. The person's request and the host's model are offered
beside the call, never in it.

## What it makes

| Kind | What | Into | Never |
| --- | --- | --- | --- |
| `project` | an iOS and macOS app on Granite: its Xcode project, the root that boots it, its environment and settings services and its Home page | `*.xcodeproj`, `Shared/App.swift`, `Shared/AppDelegate.swift`, `Shared/Assets.xcassets/*`, `Shared/Utility/AppRoot.swift`, `Services/EnvironmentService/*`, `Services/ConfigService/*`, `Components/Home/*`, `Tests/*`, `UITests/*` | an API's client or the app's value types |
| `kit` | a Swift package of the app's own, linked into it, for public services | `Packages/*` |  |
| `service` | a service: its state, its one writer, the work its reducers run, and its tests | `Services/*`, `Packages/*/Sources/*/Services/*`, `Tests/*OpsTests.swift` |  |
| `page` | a page that composes the app's views and reads its services; a view the app already has (a kit's FeedView) is shown by a blank page, never rewritten | `Components/*` | the views a page shows |
| `navigation` | the app's destinations and how it moves between them: tabs on iPhone, a sidebar on iPad and the Mac | `Shared/Utility/AppDestination.swift`, `Shared/Utility/Routes.swift`, `Shared/Utility/Device.swift`, `Services/LayoutService/*`, `iOS/PlatformNavigationView.swift`, `macOS/PlatformNavigationView.swift` |  |
| `modals` | the app's sheets, alerts, toasts and travelling panels, from one service | `Services/ModalService/*` |  |

## What it answers

A `granite-answer/1` answer (Granite's `Schema/GraniteAgent.md` §4.2): `paths`, `made` against `expected` by kind and
name, `problems` for what it could only do in part, `payloads` for files that keep a standard of their own, and its
own keys beside them. Craft measures each call by what it made of what it expected.

## How it refuses

With an `AgentRefusal`: a kind and reasons, each with its fix. `input` and `call` are the call's to correct; `build`,
`device`, `reach`, `model` and `host` what stood in the way; `answer` and `parse` its own bug.

## Changes

Each change made to make this agent more precise, dated, with the regime run that measured it and what it
made of what it was asked before and after (`TESTING.md`). Newest first.

### 2026-11-05 · a subview's actions bubble up to its page

Granite replaced `GraniteAction` with `bubble`/`onBubble` (Granite 7ff3352), and Loom moved to it. A page's subview no
longer stores optional closures that the page fills: each closure of a `views` line is a `GraniteBubble.Name` of the
view's own (`.recipeDetailHeaderRate`, prefixed by the view so no two collide), sent by a function of the view that
holds the exact type a route matches (`rate(_ value: Int)`), and the page routes it with `onBubble` where it draws the
view, to the action of its name. Its controls are always drawn; a closure no action routes is said in the notes. The
host's model is told the functions a subview has, and a blank page what each subview sends and how to route it.
The apps and kits it makes are pinned to Granite 7ff3352, the first with `bubble`.

Measured: not yet. The views lines read as before; the next regime chain is the first measure.

### 2026-11-04 · answer `granite-answer/1`; a blank page's given body held to the names rule

granite says what it makes (project, kit, service, page, navigation, modals) and where each lands, and answers `made` against `expected` read off the call's own lines. A body the host's model never got right is refused as kind `model`, no longer the call's to fix. A blank page's body given in the call is now checked as an asked one is: in the Margin regime (2026-11-04, turn 4) a given body named `posts` and `phase`, which the page never defined, and the pages did not build. (4210ca9)

Measured: not yet. Answers before this were pre-standard, so there is no precision to compare; the next regime chain on Margin is the first measure.

### 2026-11-04 · refuse a state field a service does not have; write Testing's names with their module

In the Margin regime (2026-11-03/04) granite took `state.nextCursor` for a state with no such field, and its Ops tests wrote a bare `Comment` beside `import Testing`, which declares one. Both failed the build, and the model then rewrote the services by hand. (70589c8)

Measured: not yet. Answers before this were pre-standard, so there is no precision to compare; the next regime chain on Margin is the first measure.
