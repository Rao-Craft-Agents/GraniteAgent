# GraniteAgent

Everything [Granite](https://github.com/riteshpakala/Granite)-specific an iOS + macOS app needs, written from compact
lines and shipped as a Granite agent package: a new Xcode project, Granite brought into an existing one, a kit of
services, a service in the single-writer shape with its tests, a page laid out from what it shows and does, the app's
navigation, and its modals. One call makes one of them and answers the files it wrote.

It is one of the [Rao Craft Agents](https://github.com/Rao-Craft-Agents): independent packages that, tagged in prompts
along the life of a project, build an app of [Loom](https://github.com/riteshpakala/Loom)'s quality. `granite` is the
one every app starts from: `models` writes its value types, `network` its API clients, `design` and `loom` its look,
`platform` its menus and entitlements, `localize` its languages.

## How an app finds it

GraniteAgent is a `GraniteAgentPackage` (the type is `GraniteAppAgent`, since `GraniteAgents` already has a
`GraniteAgent`), and it carries a record in its binary:

```swift
@used @section("__DATA_CONST,__granite")
let graniteRecord: GraniteRoster.Record = { GraniteRoster.record(GraniteAppAgent.self) }
```

In [Craft](https://github.com/riteshpakala/Craft), install it from the Agent Store or with
`craft agents add https://github.com/Rao-Craft-Agents/GraniteAgent.git`, then say `$granite` in a request:

```
$granite start a recipe app, then a service that keeps the recipes (loaded a page at a time, kept between
launches) and a list page of them with pull to refresh and a favourite in each row's menu
```

The model writes one call per step; each shows on Craft's agent map as `granite-1`, `granite-2`…, and the files they
name are built and tested with the turn. Calls run one at a time (`lanes` 1): several makes edit the project file and
the root that holds the relays.

## What a call takes and answers

| Field | | |
|---|---|---|
| `make` | required | `project`, `package`, `link`, `service`, `component`, `navigation` or `modals` |
| `name` | project, package | the app's or the kit's name: `Recipes` |
| `bundleId`, `team` | project | `com.example.<name>` when left out; the 10-character team id |
| `type` | service, component | `Feed` makes `FeedService` (a service) or `Feed` (a page) |
| `into` | optional | the folder, relative to the project; `Services/<Type>` and `Components/<Type>` when left out; a kit's folder puts a public service in the kit |
| `state` | service, component | fields in the models syntax, one a line: `posts [Post] = []`, `selected String?`; a page's `let post Post` is an input |
| `events` | service | the work, one a line (below) |
| `relays` | service, component | `feed: FeedService`, or `Feed` |
| `layout` | component | `list`, `grid`, `detail`, `form`, `settings`, `search`, `compose`, `tabs`, `threePane`, `blank` |
| `shows`, `actions`, `views` | component | what the page draws, does, and its subviews (below) |
| `destinations`, `style` | navigation | `feed: Feed "Feed" house`; `adaptive`, `tabs`, `sidebar` or `split` |
| `root` | project, link, navigation | the root page; `Home` when left out |
| `packages` | project, package, link | pinned remote packages: `https://github.com/kean/Nuke@<revision> Nuke NukeUI` |
| `imports` | service, component | modules to import; a local package's are found on their own |
| `persist` | service | whether the state is kept between launches |
| `notes` | service, component | what the work or the page is for: what the host's model writes bodies from |
| `rounds` | optional | how many answers the model may give one body; 3 when left out |
| `directory` | the host's | the folder the host works in; a host fills it and does not show it to a model |

The answer is a `GraniteResult`: every file written or edited (`path`, `paths`, absolute, the project file and the
root included), the types written, and a sentence for each decision.

## The lines

```
load(page Int) -> posts = LemmyAPI.posts(page: page) "loads one page"     an event: -> replaces a field
more(page Int) +> posts = LemmyAPI.posts(page: page)                       +> appends a page to a list
refresh() -> posts "the first page, newest first"                          no `= call`: the model writes it

items = feed.state.posts                  shows: a role (items, item, selection, query, sidebar, title, empty)
"Appearance/Theme" = config.state.appearance        or a row of a form, its control chosen by the field's type
refresh = try await feed.load(page: 1)    actions: refresh, more, open, submit and search do what they say
favor(post Post) "Favorite" star = …       an action on an item is in its row's menu and swipe; others are toolbar buttons
row(post Post, vote (Bool) -> Void) "title, author and score, with a vote"     views: a closure is filled by the action of its name
feed: Feed "Feed" house | PostDetail       destinations: the detail after a bar shows beside it in the split style
```

A line it cannot read, a field that does not exist, a relay that would loop, a page the project does not have: the call
is refused with every reason at once, and nothing is written.

## How the output is made

| Make | What it writes |
|---|---|
| project | `<Name>.xcodeproj` from Granite's template (objectVersion 77, synchronized Shared, Components, Services, iOS, macOS, Tests and UITests; an app, unit tests and UI tests per platform, the UI tests skipped in the schemes until turned on, since they need an interactive session to drive the app; Swift 5, iOS 17, macOS 14; Granite pinned at `deb19149` with GraniteAgents), shared schemes, `@main` App and delegate, `AppCommands`, `AppRoot`, `EnvironmentService` and `ConfigService` with their Ops and tests, the `Home` page that boots the app, `modalHosted()`, the asset catalog |
| service | the struct with its tickets, lane, `set` and `binding` helpers and a ticketed entry per event; its center (`TransientState`, or a persisted `GraniteState` that reads old files); `Set` with a case per field; a reducer per event that marks the start in `reduce` and works in `effect`; `Ops.apply`; Ops tests; a relay in the root |
| component | `<Page>`, `+Center`, `+View` (loading, empty, an error banner with a retry, pull to refresh, load more, a context menu and swipe per item, a toolbar, the first load gated on `isLoaded`), `+Actions`, reducers when asked, and `Views/<Page>.<Role>View.swift` per subview |
| navigation | `AppDestination`, `PlatformNavigationView` for iOS and macOS, `LayoutService`, `Routes` over Granite's router, `Device`, and the root page shown with them |
| modals | `ModalService` (sheets with detents, alerts, toasts, travelling panels, Mac windows; state holds ids, a registry the views), its host views, and the real `modalHosted()` |
| package | `Package.swift`, `<Name>Root`, a test target; inside an app, `Packages/<Name>` linked into every app target |
| link | Granite linked into every app target, Swift 5 on app targets that were on 6, the root, the boot and settings services and a root page written beside the app's code (file references and build files in a project of classic groups), and the root page mounted around the view the App showed |

Everything is made from the lines. The host's model is asked only for what is the app's own: the body of work no
`= call` says how to do, a subview's body its line describes, a blank page. Each answer is checked, parsed with
`swiftc -parse` in its file, and asked again with what was wrong; its examples come from another app. Every file is
staged and parsed, and the project file read by `plutil`, before any lands.

## In Craft

An app that uses Swift packages, as every Granite app does, builds only by a scheme: `xcodebuild` with no scheme
cannot resolve a package product. Craft's checks build an Xcode project with `xcodebuild build` unless the project
says otherwise, so give Craft the project's own command in its settings for the project (or for one run with
`CRAFT_CONFIG_OVERLAY`):

```json
{"build": {"command": "xcodebuild -scheme Hearth-macOS -destination platform=macOS build",
           "testCommand": "xcodebuild -scheme Hearth-macOS -destination platform=macOS test"}}
```

With no `team`, the Mac app is signed to run locally (ad hoc) and is the project's first target, so it builds and
runs on this Mac before a team is chosen. The UI tests are in the schemes but skipped until turned on, since they
need an interactive session to drive the app.

## Testing

```
swift test                     # the record, the schema, the lines, every make's files, the project file's edits
GRANITE_BUILD=1 swift test     # a recipe app made call by call, built and tested on macOS, built for the iOS
                               # simulator, its kit tested; a fresh Xcode project linked, built and tested
```

MIT licensed.
