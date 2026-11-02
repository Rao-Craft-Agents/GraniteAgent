# Testing GraniteAgent

How `granite` is tested: its own suite, its gated build of real output, and prompts run through
[Craft](https://github.com/riteshpakala/Craft) on a Mac with Craft's own local model, each logged below verbatim with
what came out. A prompt is run as a person would type it, in a project folder, with `$` naming the agent; nothing is
edited between the prompt and the screenshots. A test that needs a server uses mock backend responses, never a live
service.

## The suite

```
swift test                                  # the record, the schema, the lines, the files, a call through the roster
GRANITE_BUILD=1 swift test --filter GraniteBuildTests   # the output built for real (gated, minutes)
```

## Prompts run on this Mac

Setup: MacBook Pro M4 Max (128 GB), macOS 27, Xcode 27.1, Craft built from `main`, the model Craft loads
(`rao-studios/Qwen3-Coder-Next-REAP-48B-A3B-mlx-4bit`), permission mode bypass, the agent installed from this repository
with `craft agents add`.

### 1. A new iOS and macOS app, Hearth, in a folder that holds only its build command

*2026-11-01 · Qwen3-Coder-Next-REAP-48B-A3B-mlx-4bit · 1523 s*

**The prompt**, verbatim:

```text
$granite make a new iOS and macOS app here called Hearth, bundle id nyc.rao.hearth: a cozy recipe-sharing community app. Just the project and its foundation for now.
```

**The call the model wrote** to `granite`:

```json
{
  "bundleId": "nyc.rao.hearth",
  "make": "project",
  "name": "Hearth"
}
```

**What `granite` wrote** (28 files): `Hearth.xcodeproj/project.pbxproj`, `Hearth.xcodeproj/project.xcworkspace/contents.xcworkspacedata`, `Hearth.xcodeproj/xcshareddata/xcschemes/Hearth-iOS.xcscheme`, `Hearth.xcodeproj/xcshareddata/xcschemes/Hearth-macOS.xcscheme`, `Shared/App.swift`, `Shared/AppDelegate.swift`, `Shared/Assets.xcassets/Contents.json`, `Shared/Assets.xcassets/AccentColor.colorset/Contents.json`, `Shared/Assets.xcassets/AppIcon.appiconset/Contents.json`, `Shared/Utility/AppRoot.swift`, `Shared/Utility/ModalHosting.swift`, `macOS/AppCommands.swift`, `Components/Home/Home.swift`, `Components/Home/Home+Center.swift`, `Components/Home/Home+View.swift`, `Services/EnvironmentService/EnvironmentService.swift`, `Services/EnvironmentService/EnvironmentService+Center.swift`, `Services/EnvironmentService/Reducers/EnvironmentService.Set.swift`, `Services/EnvironmentService/Reducers/EnvironmentService.Boot.swift`, `Services/EnvironmentService/Ops/EnvironmentOps.swift`, `Services/ConfigService/ConfigService.swift`, `Services/ConfigService/ConfigService+Center.swift`, `Services/ConfigService/Reducers/ConfigService.Set.swift`, `Services/ConfigService/Ops/ConfigOps.swift`, `Services/ConfigService/Models/AppAppearance.swift`, `Tests/HearthTests.swift`, `UITests/HearthUITests.swift`, `.gitignore`

**Craft's checks**: `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed; `xcodebuild build` failed

**Verified by hand**:
- `xcodebuild -scheme Hearth-macOS -destination platform=macOS build`: BUILD SUCCEEDED
- Built for the iPhone 18 Pro simulator, installed and launched: it boots and shows its ready screen

![Hearth on the iPhone 18 Pro simulator, just after the call: booted, its foundation ready, in light and dark](Docs/Testing/1-1-granite-pair.png)
*Hearth on the iPhone 18 Pro simulator, just after the call: booted, its foundation ready, in light and dark*

![The outcome card](Docs/Testing/1-1-card.png)
*The outcome card*

**Notes**:
- The folder began with a two-line Makefile naming the app's scheme, so Craft treats it as a project; in an empty folder Craft checks a new unit with the model's own sketch command.
- The model called granite once, then only built the app by its scheme itself; it changed no file of the 28 the agent wrote.
- The turn ran to Craft's 25-minute limit because Craft's check of a newly made Xcode unit runs a bare `xcodebuild build` inside Hearth.xcodeproj ("'project.pbxproj' is not a project file") and ignores the project's build command; an app with Swift packages builds only by a scheme. A Craft finding, reported; the app itself builds.

### 2. Hearth's services over the mock client, first try (the journey's sixth prompt)

*2026-11-01 · Qwen3-Coder-Next-REAP-48B-A3B-mlx-4bit · 467 s*

**The prompt**, verbatim:

```text
Give Hearth its services with $granite, each working through HearthKit's HearthClient.current: a FeedService that keeps the feed's posts and its sort (hot, new or top), loads the first page, appends the next one, and votes on and saves a post; a ThreadService that loads a post's comments a page at a time; a CommunitiesService that keeps the communities and loads them; and a SessionService that signs in with a username and password, keeps the signed-in person, and signs out.
```

**The call the model wrote** to `granite`:

```json
{
  "bundleId": "com.example.hearth",
  "make": "project",
  "name": "Hearth"
}
```

**The call the model wrote** to `granite`:

```json
{
  "make": "link"
}
```

**The call the model wrote** to `granite`:

```json
{
  "events": [
    "load(page Int, sort String) -> posts = HearthClient.current.posts(page: page, sort: sort) \"loads a page of posts with the current sort\""
  ],
  "make": "service",
  "persist": true,
  "relays": [
    "client: HearthClient"
  ],
  "state": [
    "posts [Post] = []",
    "sort String = \"hot\""
  ],
  "type": "Feed"
}
```

**The call the model wrote** to `granite`:

```json
{
  "make": "service",
  "state": [],
  "type": "HearthClient"
}
```

**The call the model wrote** to `granite`:

```json
{
  "events": [
    "load(page Int, sort String) -> posts = HearthClient.current.posts(page: page, sort: sort) \"loads a page of posts with the current sort\"",
    "appendNextPage(page Int, sort String) +> posts = HearthClient.current.posts(page: page, sort: sort) \"appends the next page of posts\"",
    "vote(id Int, action VoteAction) = HearthClient.current.votePost(action, id: id) \"votes on a post\"",
    "save(id Int) = HearthClient.current.savePost(id) \"saves a post\""
  ],
  "make": "service",
  "persist": true,
  "state": [
    "posts [Post] = []",
    "sort String = \"hot\""
  ],
  "type": "Feed"
}
```

**The call the model wrote** to `granite`:

```json
{
  "events": [
    "loadComments(postId Int, page Int) -> comments = HearthClient.current.comments(id: postId, page: page) \"loads a page of comments for a post\"",
    "appendNextPage(postId Int, page Int) +> comments = HearthClient.current.comments(id: postId, page: page) \"appends the next page of comments\""
  ],
  "make": "service",
  "persist": false,
  "state": [
    "comments [Comment] = []",
    "postId Int = 0"
  ],
  "type": "Thread"
}
```

**The call the model wrote** to `granite`:

```json
{
  "events": [
    "load(page Int) -> communities = HearthClient.current.communities(page: page) \"loads a page of communities\"",
    "appendNextPage(page Int) +> communities = HearthClient.current.communities(page: page) \"appends the next page of communities\""
  ],
  "make": "service",
  "persist": true,
  "state": [
    "communities [Community] = []"
  ],
  "type": "Communities"
}
```

**The call the model wrote** to `granite`:

```json
{
  "events": [
    "signIn(username String, password String) = HearthClient.current.signIn(user: username, password: password) \"signs in with username and password\"",
    "currentUser = HearthClient.current.currentUser() \"loads the current user\"",
    "signOut = HearthClient.current.signOut() \"signs out\""
  ],
  "make": "service",
  "persist": true,
  "state": [
    "currentUser User? = nil",
    "isSignedIn Bool = false"
  ],
  "type": "Session"
}
```

**What `granite` wrote** (42 files): `Tests/BootTests.swift`, `Services/HearthClientService/HearthClientService.swift`, `Services/HearthClientService/HearthClientService+Center.swift`, `Services/HearthClientService/Reducers/HearthClientService.Set.swift`, `Services/HearthClientService/Ops/HearthClientOps.swift`, `Tests/HearthClientOpsTests.swift`, `Shared/Utility/AppRoot.swift`, `Services/FeedService/FeedService.swift`, `Services/FeedService/FeedService+Center.swift`, `Services/FeedService/Reducers/FeedService.Set.swift`, `Services/FeedService/Reducers/FeedService.Load.swift`, `Services/FeedService/Reducers/FeedService.AppendNextPage.swift`, `Services/FeedService/Reducers/FeedService.Vote.swift`, `Services/FeedService/Reducers/FeedService.Save.swift`, `Services/FeedService/Ops/FeedOps.swift`, `Tests/FeedOpsTests.swift`, `Shared/Utility/AppRoot.swift`, `Services/ThreadService/ThreadService.swift`, `Services/ThreadService/ThreadService+Center.swift`, `Services/ThreadService/Reducers/ThreadService.Set.swift`, `Services/ThreadService/Reducers/ThreadService.LoadComments.swift`, `Services/ThreadService/Reducers/ThreadService.AppendNextPage.swift`, `Services/ThreadService/Ops/ThreadOps.swift`, `Tests/ThreadOpsTests.swift`, `Shared/Utility/AppRoot.swift`, `Services/CommunitiesService/CommunitiesService.swift`, `Services/CommunitiesService/CommunitiesService+Center.swift`, `Services/CommunitiesService/Reducers/CommunitiesService.Set.swift`, `Services/CommunitiesService/Reducers/CommunitiesService.Load.swift`, `Services/CommunitiesService/Reducers/CommunitiesService.AppendNextPage.swift` …

**What the model changed itself**: `Services/FeedService/Reducers/FeedService.Save.swift`, `Services/CommunitiesService/Reducers/CommunitiesService.Load.swift`, `Services/CommunitiesService/Reducers/CommunitiesService.AppendNextPage.swift`, `Services/ThreadService/Reducers/ThreadService.LoadComments.swift`, `Services/ThreadService/Reducers/ThreadService.AppendNextPage.swift`, `Services/FeedService/Reducers/FeedService.Load.swift`, `Services/FeedService/Reducers/FeedService.AppendNextPage.swift`, `Tests/ThreadOpsTests.swift`

**Verified by hand**:
- The macOS scheme builds, and `xcodebuild test` passes: 41 tests in 7 suites, the services' Ops tests among them.

![The turn: eight calls to granite, two refused, and six reducers the model fixed by hand](Docs/Testing/2-6a-services.png)
*The turn: eight calls to granite, two refused, and six reducers the model fixed by hand*

**Notes**:
- Asked for four services, the model first called `make: project` (refused: Hearth is already a project) and `make: link`, which wrote `Tests/BootTests.swift`: the boot tests `make: project` had written as `HearthTests.swift`, again.
- Its first Feed call held `client: HearthClient` as a relay. Refused with "`HearthClientService` is not in the project: make it first", the model made an empty HearthClientService that nothing uses.
- Each `-> posts = HearthClient.current.posts(…)` was written into a reducer typed `[Post]` around a call answering `PostPage`; Craft's build failed, and the model rewrote six reducers by hand until its context filled.
- Fixed in the next release: link finds the boot tests by what they hold, a relay to a type that is not a service is refused as "called, not relayed", and a call answering an envelope is read for the field's list (`.posts`) with a note saying so. The same prompt was run again (entry 3).
