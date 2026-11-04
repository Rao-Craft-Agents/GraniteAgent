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

## Conformance on Hearth

Level 1 of the regime: the call a model should write, sent straight to the installed runner over its wire
(granite-agent/1) with no model, on a copy of Hearth as the journey left it (services, mock data and loom's views
made), then checked by building, testing and screenshotting the app. A pass here means the agent can produce the
result deterministically; whether Craft's model writes this call is tested by the prompts above.

### Hearth's navigation

*2026-11-01 · straight to the runner, no model*

**The call**:

```json
{
  "make": "navigation",
  "destinations": [
    "feed: Feed \"Feed\" house"
  ],
  "style": "adaptive"
}
```

**Checks**:
- a tab bar on iPhone, a sidebar on iPad and the Mac; `-destination feed` opens the Feed
- macOS build: BUILD SUCCEEDED

## Combinations

Level 3 of the regime (`TESTING-REGIME.md`): one prompt a turn chaining agents, run through Craft on a local model,
on Margin (a book-club app made from nothing). The same section is in LoomAgent's and GraniteAgent's TESTING.md, since
both are in every combination. Rows are oldest first, so the fixes read as a before/after line; each run's entry
follows the table.

Every run here is written by `regime.sh publish` from the regime's own records (`regime/runs/<run>`), never by hand;
the runs recorded before 2026-11-04 were cleared so that every run is measured the same way.

Columns: the variant, query expansion and the window; wall seconds, and how many of them were spent inside agents;
seconds to the first agent call; agent calls made / refused / refused then corrected; what the agents made of what
their calls expected; files the model wrote by hand; the peak prompt against the window and how many times the turn
made room; the regime's bars passed and whether the base case held; how the turns stopped; the builds.

| Run | Date | Variant · expand · window | Wall s (agents) | First agent s | Agents m/r/c | Made / expected | By hand | Peak · room made | Bars | Stop | Build |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [replay-2026-11-03-2-t1-2](#replay-2026-11-03-2-t1-2) | 2026-11-04 | baseline · on · 64k | 1484 (572) | 313.7 | 1 / 0 / 0 | 5 of 5 | 2 | 71% · 1 | 9/14 · not yet | loopLimit ×1 | both succeeded |

### replay-2026-11-03-2-t1-2

*2026-11-04 · Qwen3-Coder-Next-REAP-48B-A3B-mlx-4bit · baseline · expand on · 64k window · stage P0 · max_rows 4 · Craft 6e950df3619c+dirty (committed as a7bbf02) · Frigate c5b68d76f0b7 · granite 4210ca9 · loom bcf0c85 · mocks 3bea47d · network dbac458 · screenshots 22186ba · replay of turn 1 of 2026-11-03-2*

**Prompts**, one a turn, verbatim (`regime/prompts/`):

> **t1 mocks**: Give Margin believable data with $mocks until the server exists: readers with handles and faces, the book clubs they post in, posts in the voice of people talking through the chapters they are reading, and comment threads with depth; counts posts: 40, comments: 120, people: 20, communities: 6.

**Time**: 1484 s in all; 572 s inside agents, 912 s the model and Craft; first agent call at 313.7 s.

| Turn | Wall s | Prompt Σ | Completion Σ | Reused | Agents m/r/c | By hand | Stop |
|---|---|---|---|---|---|---|---|
| t1 mocks | 1484 | 366,406 | 10,034 | 75% | mocks 1/0/0 | 2 | loopLimit |

**Agents**, across the run (`granite-answer/1`: what each made of what its calls expected):

| Agent | Revision | Calls m/r/c | Made of expected | Not made | Problems | Refusals by kind | Asks (tokens) |
|---|---|---|---|---|---|---|---|
| `mocks` | 3bea47d | 1 / 0 / 0 | 5 of 5 (100%) | — | — | — | 30 (15,864) |

**Who wrote what**:

- `mocks`: 18 files: Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/CommentsFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/CommunitiesFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/CreateCommentFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/CreatePostFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/PostsFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/UserFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/Fixtures/UserPostsFixture.swift, Packages/MarginKit/Sources/MarginKit/Mocks/MarginClient+Mock.swift, …
- by hand: 2 files: Packages/MarginKit/Sources/MarginKit/Transport/MockTransport.swift, Packages/MarginKit/Tests/MarginKitTests/Support/Samples.swift

**Bars**: 9 of 14 passed · base case not yet

**Checks**: mocks_decodes pass · mocks_counts pass · mocks_stems pass · mocks_threads pass · services **fail** · loom_screens **fail** · pages **fail** · build_macos pass · build_ios pass · tests pass · feed_draws_light **fail** · feed_draws_dark **fail** · agents_made pass · refusals_typed pass · hand_per_turn pass · refusals_corrected pass · no_cargo pass · trail pass

- services: FeedService: no folder; PostService: no folder; ProfileService: no folder; no *OpsTests.swift
- loom_screens: missing FeedView, PostPageView, CommentThreadView, ProfileView; no conformance names Post, Comment, User, Community
- pages: no page draws FeedView; no page draws PostPageView or CommentThreadView; no page draws ProfileView; no AppDestination
- feed_draws_light: no mock title on the feed: 9:41 | 00 | Margin | Everything is in place.
- feed_draws_dark: no mock title on the feed: 9:41 | Margin | Everything is in place.

**Stopped**: t1 loopLimit

**Build**: iOS: succeeded · macOS: succeeded

**Notes**:

- Turn 1 run again from the state `2026-11-03-2` left before it; the chain started at 2026-11-03-2.
- The trail is `regime/runs/replay-2026-11-03-2-t1-2/Margin`: open it in Craft and type `#lantern`.

![Outcome card for replay-2026-11-03-2-t1-2](Docs/Testing/l3-replay-2026-11-03-2-t1-2-card.png)
*Outcome card for replay-2026-11-03-2-t1-2*

![iPhone, dark: the launch page (no feed destination was found)](Docs/Testing/l3-replay-2026-11-03-2-t1-2-launch-dark.png)
*iPhone, dark: the launch page (no feed destination was found)*

![iPhone, light: the launch page (no feed destination was found)](Docs/Testing/l3-replay-2026-11-03-2-t1-2-launch-light.png)
*iPhone, light: the launch page (no feed destination was found)*

![The contact sheet the screenshots agent wrote](Docs/Testing/l3-replay-2026-11-03-2-t1-2-sheet.png)
*The contact sheet the screenshots agent wrote*
