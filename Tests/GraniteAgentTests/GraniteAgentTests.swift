import Foundation
import GraniteAgents
import XCTest
@testable import GraniteAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class GraniteAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let granite = try XCTUnwrap(GraniteRoster.discovered().package("granite"), "the record is in this test binary")
        XCTAssertEqual(granite.module, "GraniteAgent")
        XCTAssertEqual(granite.summary, GraniteAppAgent.summary)
        XCTAssertEqual(granite.lanes, 1, "calls edit the files several makes share, one at a time")
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let granite = AnyAgentPackage(GraniteAppAgent.self)
        let lines: GraniteSchema = .array(.string)
        XCTAssertEqual(granite.schema, .object([
            .init(name: "make", schema: .choice(["project", "package", "link", "service", "component", "navigation", "modals"]), required: true),
            .init(name: "name", schema: .string, required: false),
            .init(name: "bundleId", schema: .string, required: false),
            .init(name: "team", schema: .string, required: false),
            .init(name: "type", schema: .string, required: false),
            .init(name: "into", schema: .string, required: false),
            .init(name: "state", schema: lines, required: false),
            .init(name: "events", schema: lines, required: false),
            .init(name: "relays", schema: lines, required: false),
            .init(name: "layout", schema: .choice(["list", "grid", "detail", "form", "settings", "search", "compose", "tabs", "threePane", "blank"]), required: false),
            .init(name: "shows", schema: lines, required: false),
            .init(name: "actions", schema: lines, required: false),
            .init(name: "views", schema: lines, required: false),
            .init(name: "body", schema: .string, required: false),
            .init(name: "destinations", schema: lines, required: false),
            .init(name: "style", schema: .choice(["adaptive", "tabs", "sidebar", "split"]), required: false),
            .init(name: "root", schema: .string, required: false),
            .init(name: "packages", schema: lines, required: false),
            .init(name: "imports", schema: lines, required: false),
            .init(name: "persist", schema: .boolean, required: false),
            .init(name: "notes", schema: .string, required: false),
            .init(name: "rounds", schema: .integer, required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(granite.takesDirectory)
        XCTAssertEqual(Set(granite.fields.keys), Set(granite.schema.fields.map(\.name)).subtracting(["directory"]),
                       "a note beside every field the model sees, and none for the host's folder")
    }

    func testTheGuideTeachesEveryMakeWithAnExample() {
        let guide = AnyAgentPackage(GraniteAppAgent.self).guide
        for make in GraniteMake.allCases { XCTAssertTrue(guide.contains("{\"make\": \"\(make.rawValue)\""), "an example call for \(make.rawValue)") }
        for layout in GraniteLayout.allCases { XCTAssertTrue(guide.contains(layout.rawValue), "the guide names the \(layout.rawValue) layout") }
        for word in ["-> field", "+> field", "= call", "relays", "items =", "selection", "\"Section/Label\"", "refresh", "more", "persist",
                     "destinations", "modals.sheet", "Packages/RecipeKit", "ContentView", "let recipe Recipe", "Not for"] {
            XCTAssertTrue(guide.contains(word), "the guide says \(word)")
        }
    }

    /// The call as a host makes it: JSON in, the folder in the JSON, JSON out naming the files.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["make": "project", "name": "Recipes", "directory": folder.path])
        let answer = try await AnyAgentPackage(GraniteAppAgent.self).perform(input, host: AgentHost(directory: folder.path, ask: "a recipe app"))
        let result = try JSONDecoder().decode(GraniteResult.self, from: answer)
        XCTAssertEqual(result.make, "project")
        XCTAssertEqual(result.path, result.paths.first)
        XCTAssertTrue(result.paths.contains(folder.appendingPathComponent("Recipes.xcodeproj/project.pbxproj").path))
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path + "/"), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        XCTAssertEqual(result.types.first, "RecipesApp")
    }

    /// A host over the wire may give its folder only beside the call: the files land there, not in the folder the
    /// runner was started in.
    /// The answer keeps `granite-answer/1`: stamped by the runner, what the call made held against what it asked
    /// for, and every kind one `makes` declares (Margin regime, 2026-11-04).
    func testTheAnswerSaysWhatItMadeOfWhatItWasAsked() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["make": "project", "name": "Recipes", "directory": folder.path])
        let answer = try await AnyAgentPackage(GraniteAppAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: answer) as? [String: Any])
        XCTAssertEqual(json["format"] as? String, AgentAnswerStandard.format)
        let result = try JSONDecoder().decode(GraniteResult.self, from: answer)
        XCTAssertEqual(result.expected, [AgentExpected(kind: "project", name: "Recipes")])
        XCTAssertEqual(result.made.map(\.name), ["Recipes"])
        XCTAssertTrue(result.made[0].path?.hasSuffix("Shared/Utility/AppRoot.swift") == true, "\(result.made)")
        XCTAssertEqual(result.made[0].state, .written)
        let kinds = Set(GraniteAppAgent.makes.map(\.kind))
        for make in GraniteMake.allCases { XCTAssertTrue(kinds.contains(GraniteMeasure.kind(make)), "\(make) is a kind granite declares") }

        let service = try await Fixture.call(Fixture.recipesService, in: try appWithRecipe())
        XCTAssertEqual(service.expected, [AgentExpected(kind: "service", name: "RecipesService")])
        XCTAssertEqual(service.made.map(\.name), ["RecipesService"])
        let again = try await Fixture.call(Fixture.recipesService, in: URL(fileURLWithPath: service.paths[0]).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent())
        XCTAssertEqual(again.made.first?.state, .rewritten, "the service was there before")
        let destinations = GraniteMeasure.expected(GraniteAppAgent.Input(make: .navigation, destinations: [#"feed: FeedPage "Feed" house"#, #"profile: ProfilePage "Profile" person"#]))
        XCTAssertEqual(destinations.map(\.name), ["feed", "profile"])
    }

    /// A refusal says its kind: the call's to fix, the model's when its rounds ran out, the Swift that did not parse.
    func testARefusalSaysWhoseItIs() {
        XCTAssertEqual(GraniteError.refused(["a", "b"]).refusal, AgentRefusal(.call, ["a", "b"]))
        XCTAssertEqual(GraniteError.unanswered(["x did not come out right in 3 rounds"]).refusal.kind, .model)
        XCTAssertEqual(GraniteError.line("load(", "a call is closed").refusal, AgentRefusal(.call, "`load(`: a call is closed"))
        XCTAssertEqual(AgentFilesError.unparsed("x.swift:1: error").refusal.kind, .parse)
    }

    private func appWithRecipe() async throws -> URL {
        let folder = try Fixture.folder()
        _ = try await Fixture.call(Fixture.project, in: folder)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Shared/Models"), withIntermediateDirectories: true)
        try Fixture.recipe.write(to: folder.appendingPathComponent("Shared/Models/Recipe.swift"), atomically: true, encoding: .utf8)
        return folder
    }

    func testTheHostsFolderIsUsedWhenTheCallGivesNone() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["make": "project", "name": "Pantry"])
        let answer = try await AnyAgentPackage(GraniteAppAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(GraniteResult.self, from: answer)
        XCTAssertFalse(result.paths.isEmpty)
        for path in result.paths { XCTAssertTrue(path.hasPrefix(folder.path + "/"), "\(path) is under the host's folder") }
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Pantry.xcodeproj/project.pbxproj").path))
    }

    func testARefusalNamesEveryReasonAndWritesNothing() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["make": "project", "name": "1 Bad", "bundleId": "nope", "team": "abc", "root": "Settings"])
        do {
            _ = try await AnyAgentPackage(GraniteAppAgent.self).perform(input, host: AgentHost(directory: folder.path))
            XCTFail("a project with a bad name is refused")
        } catch {
            let text = "\(error)"
            for reason in ["must start with a letter", "not a bundle identifier", "not a team", "cannot be named `Settings`"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [])
    }
}
