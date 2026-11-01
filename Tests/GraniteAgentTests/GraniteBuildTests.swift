import Foundation
import XCTest
@testable import GraniteAgent

/// The output built and run as a person's app would be: a recipe app made call by call (a project, a kit, services
/// with an expression and with a body from the model, every page layout, navigation and modals), its Loom layout
/// checked, built and tested on macOS, built for the iOS simulator, its kit tested with SwiftPM; and a fresh Xcode
/// project linked and built. Gated (`GRANITE_BUILD=1`): a build takes minutes and fetches Granite.
final class GraniteBuildTests: XCTestCase {
    /// Where builds keep their packages between runs, under the process's temporary files.
    private let packages = FileManager.default.temporaryDirectory.appendingPathComponent("granite-agent-packages", isDirectory: true)

    private func xcodebuild(_ arguments: [String], in folder: URL, derived: URL, home: URL? = nil) throws -> Shell.Run {
        var environment: [String: String] = [:]
        // The test host is the app: it boots and saves its settings, under a home of the test's own, not the person's.
        if let home { environment["TEST_RUNNER_CFFIXED_USER_HOME"] = home.path }
        return try Shell.run(["xcrun", "xcodebuild"] + arguments + ["-derivedDataPath", derived.path, "-clonedSourcePackagesDirPath", packages.path,
                                                                    "-skipPackagePluginValidation", "-skipMacroValidation"], in: folder, environment: environment)
    }

    func testTheRecipeAppBuildsAndItsTestsPassOnBothPlatforms() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["GRANITE_BUILD"] == "1", "set GRANITE_BUILD=1 to build the output")
        let folder = try Fixture.folder()
        let app = folder.appendingPathComponent("Recipes")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)

        try await Fixture.call(Fixture.project, in: app)
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Shared/Models"), withIntermediateDirectories: true)
        try Fixture.recipe.write(to: app.appendingPathComponent("Shared/Models/Recipe.swift"), atomically: true, encoding: .utf8)
        let model = Fixture.model()
        try await Fixture.call(Fixture.kit, in: app)
        try await Fixture.call(Fixture.recipesService, in: app)
        try await Fixture.call(Fixture.pantry, in: app, model: model)
        for page in [Fixture.recipeList, Fixture.settings, Fixture.search, Fixture.grid, Fixture.detail, Fixture.compose, Fixture.tabs, Fixture.browser, Fixture.today] {
            try await Fixture.call(page, in: app, model: model)
        }
        try await Fixture.call(Fixture.navigation, in: app)
        try await Fixture.call(Fixture.modals, in: app)
        XCTAssertEqual(model.asked.count, 4, "the pantry's work twice (its first answer does not parse), a subview, a page")

        let layout = try Shell.run(["python3", NSString(string: "~/.claude/skills/loom-app-architecture/scripts/check_layout.py").expandingTildeInPath, app.path], in: folder)
        XCTAssertTrue(layout.log.contains("0 error(s)"), layout.log)

        let derived = folder.appendingPathComponent("DerivedData")
        let home = folder.appendingPathComponent("home")
        let mac = try xcodebuild(["-project", "Recipes.xcodeproj", "-scheme", "Recipes-macOS", "-destination", "platform=macOS",
                                  "CODE_SIGNING_ALLOWED=NO", "-skip-testing:RecipesUITests-macOS", "build", "test"], in: app, derived: derived, home: home)
        XCTAssertEqual(mac.status, 0, Shell.digest(mac.log))
        XCTAssertTrue(mac.log.contains("** TEST SUCCEEDED **"), Shell.digest(mac.log))
        XCTAssertTrue(mac.log.contains("Test run with 27 tests in 4 suites passed"), Shell.digest(mac.log))
        XCTAssertFalse(mac.log.contains(": warning: "), "the app builds without a warning: \(mac.log.components(separatedBy: "\n").filter { $0.contains(": warning: ") }.prefix(5))")
        XCTAssertTrue(FileManager.default.fileExists(atPath: home.appendingPathComponent("Library/Application Support/com.example.recipes/granite-db").path),
                      "the app ran, and kept its settings under the test's home")

        let iOS = try xcodebuild(["-project", "Recipes.xcodeproj", "-scheme", "Recipes-iOS", "-destination", "generic/platform=iOS Simulator", "build", "build-for-testing"],
                                 in: app, derived: derived)
        XCTAssertEqual(iOS.status, 0, Shell.digest(iOS.log))

        let kit = try Shell.run(["swift", "test", "--scratch-path", folder.appendingPathComponent("kit-build").path], in: app.appendingPathComponent("Packages/RecipeKit"))
        XCTAssertEqual(kit.status, 0, Shell.digest(kit.log))
        XCTAssertTrue(kit.log.contains("Test run with 7 tests in 2 suites passed"), Shell.digest(kit.log))
        // What a passing build leaves is only build products; a failing one keeps them to be read.
        if testRun?.totalFailureCount == 0 { [derived, folder.appendingPathComponent("kit-build")].forEach { try? FileManager.default.removeItem(at: $0) } }
    }


    func testALinkedProjectBuildsOnBothPlatforms() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["GRANITE_BUILD"] == "1", "set GRANITE_BUILD=1 to build the output")
        let folder = try Fixture.folder()
        let project = folder.appendingPathComponent("Greeter")
        try ClassicProject.write(to: project)
        try await Fixture.call(GraniteAppAgent.Input(make: .link), in: project)
        let derived = folder.appendingPathComponent("DerivedData")
        let mac = try xcodebuild(["-project", "Greeter.xcodeproj", "-scheme", "Greeter", "-destination", "platform=macOS", "CODE_SIGNING_ALLOWED=NO", "build", "test"],
                                 in: project, derived: derived, home: folder.appendingPathComponent("home"))
        XCTAssertEqual(mac.status, 0, Shell.digest(mac.log))
        XCTAssertTrue(mac.log.contains("BootTests/bootingMarksTheAppReady()") && mac.log.contains("** TEST SUCCEEDED **"), Shell.digest(mac.log))
        let iOS = try xcodebuild(["-project", "Greeter.xcodeproj", "-scheme", "Greeter", "-destination", "generic/platform=iOS Simulator", "build"],
                                 in: project, derived: derived)
        XCTAssertEqual(iOS.status, 0, Shell.digest(iOS.log))
        if testRun?.totalFailureCount == 0 { try? FileManager.default.removeItem(at: derived) }
    }
}

