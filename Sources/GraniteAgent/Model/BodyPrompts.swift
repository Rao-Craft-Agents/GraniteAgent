//  WHAT: What the host's model is told when it writes a body: the rules a body keeps, and one worked example from
//        another app (a recipe app) to copy the shape of.
//  PIN:  THE EXAMPLE IS ANOTHER APP'S. A local model copies the example it is shown; one drawn from the app it is
//        writing for would come back with the example's names.

import Foundation

enum BodyPrompts {
    static let work = #"""
    You write the body of one async throwing Swift function in an iOS and macOS app. The app keeps its state in Granite services; the function is the work one of them does. Answer with one JSON object, {"body": "…"}: the statements only, with no signature and no braces around them.

    Rules:
    - Use only the function's parameters, the services it is given (call their entries with `try await`) and the types listed.
    - When the function returns a value, end every path with `return` and a value of the return type.
    - When there is nothing to return, throw an error rather than inventing data: `throw URLError(.badServerResponse)`.
    - No force unwraps, no `fatalError`, no `print`, no placeholder comments. Swift 5.10 with Foundation.

    An example from another app (a recipe app), to copy the shape of and never the names:
    Function: static func work(query: String, catalog: CatalogService) async throws -> [Recipe]
    What it does: finds the recipes whose title has the query, newest first.
    Answer: {"body": "let all = try await catalog.recipes()\nreturn all\n    .filter { $0.title.localizedCaseInsensitiveContains(query) }\n    .sorted { $0.added > $1.added }"}
    """#

    static let view = #"""
    You write the body of one SwiftUI view in an iOS 17 and macOS 14 app. Answer with one JSON object, {"body": "…"}: the Swift that goes inside `var body: some View { … }`, nothing else.

    Rules:
    - Use only the view's properties listed, and the fields of their types. What the view does is one of its functions listed (`func save()`, `func rate(_ value: Int)`): call it from its control (`Button("Save") { save() }`), which is always drawn. Never declare them again, and never add closures: the page routes what they send.
    - Every word a person reads is a literal SwiftUI localizes: Text("Reply"), Button("Share"), Label("Saved", systemImage: "bookmark"). A value from the data is shown as it is: Text(recipe.title).
    - An icon-only control gets .accessibilityLabel(Text("…")).
    - System text styles (.headline, .subheadline, .caption) so Dynamic Type works; semantic colours (.primary, .secondary, .tint, Color.secondary.opacity(0.15)) so light and dark both read.
    - Nothing that only one platform has unless it is inside #if os(iOS) / #if os(macOS). No UIKit or AppKit types.
    - No force unwraps, no `fatalError`, no `print`, no placeholder comments, no fixed heights on text.

    An example from another app (a recipe app), to copy the shape of and never the names:
    View: struct RecipeCardView: View { let recipe: Recipe; func favorite(_ value: Bool) }
    Recipe: title String, minutes Int, photo URL?, isFavorite Bool
    What it shows: the photo, the title, how long it takes, and a heart to favourite it
    Answer: {"body": "HStack(alignment: .top, spacing: 12) {\n    AsyncImage(url: recipe.photo) { image in\n        image.resizable().scaledToFill()\n    } placeholder: {\n        Color.secondary.opacity(0.15)\n    }\n    .frame(width: 56, height: 56)\n    .clipShape(RoundedRectangle(cornerRadius: 10))\n    VStack(alignment: .leading, spacing: 4) {\n        Text(recipe.title).font(.headline)\n        Label(\"\\(recipe.minutes) min\", systemImage: \"clock\").font(.caption).foregroundStyle(.secondary)\n    }\n    Spacer(minLength: 0)\n    Button { favorite(!recipe.isFavorite) } label: {\n        Image(systemName: recipe.isFavorite ? \"heart.fill\" : \"heart\")\n    }\n    .buttonStyle(.borderless)\n    .accessibilityLabel(Text(\"Favorite\"))\n}\n.padding(.vertical, 4)"}
    """#

    static let page = #"""
    You write the body of one page of an iOS 17 and macOS 14 SwiftUI app built on Granite. The page reads services through relays (`library.state.recipes`) and calls the page's actions (`Task { try? await refresh() }`). Answer with one JSON object, {"body": "…"}: the Swift that goes inside `var content: some View { … }`, nothing else: one view (a ScrollView, a List, a VStack…) with its modifiers.

    Rules:
    - Use only the relays, the page's state (`state.x`, bound with `center.$state.binding.x`), the subviews and the actions listed.
    - A subview takes values only. What it sends comes up as a bubble: route each one where the subview is drawn, by the name and type listed, to the action it means: `RecipeCardView(recipe: recipe).onBubble { On(.recipeCardFavorite, Bool.self) { value in Task { try? await favor(recipe: recipe, on: value) } } }`.
    - Every word a person reads is a literal SwiftUI localizes: Text("Today"), Button("Add"). Values from the data are shown as they are.
    - An icon-only control gets .accessibilityLabel(Text("…")). System text styles and semantic colours, so Dynamic Type, light and dark all work.
    - No force unwraps, no `fatalError`, no `print`, no placeholder comments, nothing only one platform has outside #if os(…).

    An example from another app (a recipe app), to copy the shape of and never the names:
    Relays: library: LibraryService (state: recipes [Recipe], loading String?)
    Subviews: RecipeCardView(recipe: Recipe)
    Actions: refresh() async throws
    What it shows: today's recipes as cards, newest first
    Answer: {"body": "ScrollView {\n    LazyVStack(alignment: .leading, spacing: 12) {\n        Text(\"Today\").font(.title2.bold())\n        ForEach(library.state.recipes) { recipe in\n            RecipeCardView(recipe: recipe)\n        }\n    }\n    .padding()\n}\n.refreshable { try? await refresh() }"}
    """#
}
