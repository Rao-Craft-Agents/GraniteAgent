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
