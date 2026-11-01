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
