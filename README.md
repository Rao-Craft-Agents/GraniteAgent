# GraniteAgent

Start an iOS and macOS app from a sentence, and keep growing it the same way. Say what the app is, what it keeps and
what each screen shows, and `granite` writes it as a careful SwiftUI engineer would: an Xcode project that builds and
runs on the first day, services that own their state, pages that load, refresh and recover from errors, navigation
that is tabs on iPhone and a sidebar on iPad and the Mac, and the sheets, alerts and toasts around them.

## What you can ask

```
$granite start a recipe app
$granite a service that keeps the recipes, loaded a page at a time and kept between launches
$granite a list page of the recipes with pull to refresh and a favourite in each row's menu
$granite navigation with Recipes, Search and Settings
```

Ask for one piece or a whole app in a request. Craft runs the steps one at a time and shows each on its agent map.

## What you get

- **A project that builds.** An Xcode project for iPhone, iPad and Mac with its unit and UI tests, signed to run on
  this Mac before you choose a team.
- **Services that own their state.** Each loads what it is asked to, keeps it between launches if you say so, and
  comes with its tests.
- **The pages people expect.** Lists, grids, details, forms, settings, search, compose, tabs and three-pane layouts,
  each with loading, empty and error states, pull to refresh, loading more, and the actions you named in menus,
  swipes and toolbars.
- **Navigation and modals.** Your destinations laid out for each device, and one place for the app's sheets, alerts,
  toasts and panels.
- **Granite in an app you already have.** Point it at an existing Xcode project and it links Granite and adds the
  root and settings around the app's own code, without rewriting your views.

## How it works

- It writes from what you describe, and asks the model only for what is your app's own: the body of a view you
  described, or work it cannot read off your request.
- Every file is checked before any lands. A request it cannot carry out is turned down with every reason at once and
  nothing is written, so a project is never left half changed.
- What it makes is built and tested with the turn.

## Works well with

`granite` is where an app starts. The other Rao Craft Agents fill it in: `models` writes its value types, `network`
its API clients, `design` and `loom` its look, `platform` its menus and entitlements, and `localize` its languages.

## Get it

In Craft, install Granite from the Agent Store, or run
`craft agents add https://github.com/Rao-Craft-Agents/GraniteAgent.git`, then say `$granite` in a request.

## Requirements

- A Mac on macOS 14 or later, with Xcode.
- The apps it makes target iOS 17 and macOS 14, on [Granite](https://github.com/riteshpakala/Granite).
- A Granite app builds by its scheme: give Craft the project's build command in its settings (the reference shows
  how).
- MIT licensed.

## For developers

What a call takes and answers, the lines it reads and what each make writes are in the
[reference](Docs/Reference.md). The agent standard it follows is [Schema/Granite.md](Schema/Granite.md), and how it is
measured is [TESTING.md](TESTING.md).
