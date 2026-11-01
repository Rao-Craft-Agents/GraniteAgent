import Foundation
import XCTest
@testable import GraniteAgent

/// `make: project` and the project file it writes: whole, in Granite's shape, never over another project, and the
/// edits every later make relies on.
final class ProjectTests: XCTestCase {
    private func made(_ input: GraniteAppAgent.Input = Fixture.project) async throws -> (GraniteResult, URL, Pbxproj) {
        let folder = try Fixture.folder()
        let result = try await Fixture.call(input, in: folder)
        let text = try String(contentsOf: folder.appendingPathComponent("\(input.name ?? "")/../\(input.name ?? "").xcodeproj/project.pbxproj").standardizedFileURL, encoding: .utf8)
        return (result, folder, try Pbxproj(text))
    }

    func testAProjectIsWholeInTheLoomLayout() async throws {
        let (result, folder, _) = try await made()
        let written = Set(result.paths.map { String($0.dropFirst(folder.path.count + 1)) })
        let expected: Set<String> = [
            "Recipes.xcodeproj/project.pbxproj", "Recipes.xcodeproj/project.xcworkspace/contents.xcworkspacedata",
            "Recipes.xcodeproj/xcshareddata/xcschemes/Recipes-iOS.xcscheme", "Recipes.xcodeproj/xcshareddata/xcschemes/Recipes-macOS.xcscheme",
            "Shared/App.swift", "Shared/AppDelegate.swift", "Shared/Assets.xcassets/Contents.json", "Shared/Assets.xcassets/AccentColor.colorset/Contents.json",
            "Shared/Assets.xcassets/AppIcon.appiconset/Contents.json", "Shared/Utility/AppRoot.swift", "Shared/Utility/ModalHosting.swift",
            "macOS/AppCommands.swift", "Components/Home/Home.swift", "Components/Home/Home+Center.swift", "Components/Home/Home+View.swift",
            "Services/EnvironmentService/EnvironmentService.swift", "Services/EnvironmentService/EnvironmentService+Center.swift",
            "Services/EnvironmentService/Reducers/EnvironmentService.Set.swift", "Services/EnvironmentService/Reducers/EnvironmentService.Boot.swift",
            "Services/EnvironmentService/Ops/EnvironmentOps.swift", "Services/ConfigService/ConfigService.swift", "Services/ConfigService/ConfigService+Center.swift",
            "Services/ConfigService/Reducers/ConfigService.Set.swift", "Services/ConfigService/Ops/ConfigOps.swift", "Services/ConfigService/Models/AppAppearance.swift",
            "Tests/RecipesTests.swift", "UITests/RecipesUITests.swift", ".gitignore",
        ]
        XCTAssertEqual(written, expected)
        let app = try String(contentsOf: folder.appendingPathComponent("Shared/App.swift"), encoding: .utf8)
        XCTAssertTrue(app.contains("@main\nstruct RecipesApp: App {"))
        XCTAssertTrue(app.contains("@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate"))
        XCTAssertTrue(app.contains("        #if os(macOS)\n        .commands { AppCommands() }"))
        let config = try String(contentsOf: folder.appendingPathComponent("Services/ConfigService/ConfigService+Center.swift"), encoding: .utf8)
        XCTAssertTrue(config.contains(#"@Store(persist: "persistence.Recipes.config.0001", autoSave: true, preload: true) var state: State"#))
        let home = try String(contentsOf: folder.appendingPathComponent("Components/Home/Home+View.swift"), encoding: .utf8)
        XCTAssertTrue(home.contains(".task(id: config.isLoaded) {\n            guard config.isLoaded else { return }\n            await AppRoot.shared.boot()"))
        XCTAssertTrue(home.contains(".modalHosted()"))
    }

    func testTheProjectFileIsGranitesTemplateInSwiftFive() async throws {
        let (_, _, project) = try await made()
        XCTAssertNil(Pbxproj.lint(project.text), "plutil reads it")
        XCTAssertTrue(project.text.contains("objectVersion = 77;"))
        let synchronized = project.objects("PBXFileSystemSynchronizedRootGroup").compactMap { $0.string("path") }
        XCTAssertEqual(Set(synchronized), ["Shared", "Components", "Services", "iOS", "macOS", "Tests", "UITests"])
        XCTAssertEqual(project.targets.map(\.name), ["Recipes-iOS", "Recipes-macOS", "RecipesTests-iOS", "RecipesTests-macOS", "RecipesUITests-iOS", "RecipesUITests-macOS"])
        let byName = Dictionary(uniqueKeysWithValues: project.targets.map { ($0.name, $0) })
        XCTAssertEqual(project.synchronizedFolders(of: byName["Recipes-iOS"]!), ["Shared", "Components", "Services", "iOS"])
        XCTAssertEqual(project.synchronizedFolders(of: byName["Recipes-macOS"]!), ["Shared", "Components", "Services", "macOS"])
        XCTAssertEqual(project.synchronizedFolders(of: byName["RecipesTests-macOS"]!), ["Tests"])
        for target in project.targets {
            XCTAssertEqual(project.settings(of: target)?["SWIFT_VERSION"]?.string, "5.0", target.name)
            let products = target.object.list("packageProductDependencies").compactMap { project.objects[$0]?.string("productName") }
            XCTAssertEqual(products, target.isApplication ? ["Granite", "GraniteAgents"] : [], target.name)
        }
        XCTAssertEqual(project.settings(of: byName["Recipes-iOS"]!)?["IPHONEOS_DEPLOYMENT_TARGET"]?.string, "17.0")
        XCTAssertEqual(project.settings(of: byName["Recipes-macOS"]!)?["MACOSX_DEPLOYMENT_TARGET"]?.string, "14.0")
        XCTAssertEqual(project.settings(of: byName["Recipes-macOS"]!)?["ENABLE_OUTGOING_NETWORK_CONNECTIONS"]?.string, "YES")
        XCTAssertEqual(project.settings(of: byName["RecipesTests-iOS"]!)?["TEST_HOST"]?.string,
                       "$(BUILT_PRODUCTS_DIR)/Recipes.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Recipes")
        let granite = try XCTUnwrap(project.objects("XCRemoteSwiftPackageReference").first)
        XCTAssertEqual(granite.string("repositoryURL"), GranitePin.url)
        XCTAssertEqual(granite.value["requirement"]?["revision"]?.string, GranitePin.revision)
        XCTAssertEqual(project.moduleName(of: byName["Recipes-iOS"]!), "Recipes")
        let ids = project.order
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertTrue(ids.allSatisfy { $0.range(of: #"^[0-9A-F]{24}$"#, options: .regularExpression) != nil }, "fresh 24-hex ids")
    }

    func testTheSchemesBuildAndTestTheirPlatform() async throws {
        let (_, folder, project) = try await made()
        let byName = Dictionary(uniqueKeysWithValues: project.targets.map { ($0.name, $0.id) })
        let scheme = try String(contentsOf: folder.appendingPathComponent("Recipes.xcodeproj/xcshareddata/xcschemes/Recipes-macOS.xcscheme"), encoding: .utf8)
        XCTAssertTrue(scheme.contains("BlueprintIdentifier = \"\(byName["Recipes-macOS"]!)\""))
        XCTAssertTrue(scheme.contains("BlueprintIdentifier = \"\(byName["RecipesTests-macOS"]!)\""))
        XCTAssertTrue(scheme.contains("BlueprintIdentifier = \"\(byName["RecipesUITests-macOS"]!)\""))
        XCTAssertFalse(scheme.contains(byName["Recipes-iOS"]!))
        XCTAssertNotNil(try? XMLDocument(data: Data(scheme.utf8)), "the scheme is well-formed XML")
    }

    func testPackagesAreLinkedIntoBothAppsPinned() async throws {
        var input = Fixture.project
        let revision = String(repeating: "0f", count: 20)
        input.packages = ["https://github.com/kean/Nuke@\(revision) Nuke NukeUI", "https://github.com/apple/swift-collections@1.1.4 Collections"]
        let (_, _, project) = try await made(input)
        let references = project.objects("XCRemoteSwiftPackageReference")
        XCTAssertEqual(references.count, 3)
        XCTAssertEqual(references.first { $0.string("repositoryURL") == "https://github.com/apple/swift-collections" }?.value["requirement"]?["version"]?.string, "1.1.4")
        for target in project.applicationTargets {
            let products = target.object.list("packageProductDependencies").compactMap { project.objects[$0]?.string("productName") }
            XCTAssertEqual(products, ["Granite", "GraniteAgents", "Nuke", "NukeUI", "Collections"])
            let frameworks = project.phase("PBXFrameworksBuildPhase", of: target)?.list("files") ?? []
            XCTAssertEqual(frameworks.count, 5)
        }
    }

    func testAProjectIsNeverWrittenOver() async throws {
        let (_, folder, _) = try await made()
        let before = try String(contentsOf: folder.appendingPathComponent("Shared/App.swift"), encoding: .utf8)
        do {
            try await Fixture.call(GraniteAppAgent.Input(make: .project, name: "Other"), in: folder)
            XCTFail("a second project over the first is refused")
        } catch {
            XCTAssertTrue("\(error)".contains("already holds Recipes.xcodeproj"), "\(error)")
        }
        XCTAssertEqual(try String(contentsOf: folder.appendingPathComponent("Shared/App.swift"), encoding: .utf8), before)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Other.xcodeproj").path))
    }

    func testProjectFileEditsAreIdempotent() async throws {
        let (_, _, made) = try await made()
        var project = made
        let app = project.applicationTargets[0].id
        let granite = try project.remotePackage(GranitePin.url + ".git", requirement: .revision(GranitePin.revision), name: "Granite")
        XCTAssertEqual(granite, project.objects("XCRemoteSwiftPackageReference")[0].id, "the same package, with or without .git")
        let text = project.text
        XCTAssertFalse(try project.link("Granite", package: granite, into: app))
        XCTAssertEqual(project.text, text, "a product linked already is not linked twice")
        let kit = try project.localPackage("Packages/Kit", name: "Kit")
        XCTAssertTrue(try project.link("Kit", package: kit, into: app))
        XCTAssertEqual(try project.localPackage("Packages/Kit", name: "Kit"), kit)
        XCTAssertFalse(try project.include("iOS/Thing.swift", in: project.applicationTargets.map(\.id)),
                       "a file under a synchronized folder joins the targets that folder joins, and no other")
        XCTAssertNil(Pbxproj.lint(project.text))
    }

    func testAFileJoinsAClassicProjectOnce() throws {
        let folder = try Fixture.folder()
        try ClassicProject.write(to: folder)
        var project = try Pbxproj(ClassicProject.pbxproj)
        let app = project.applicationTargets.map(\.id)
        XCTAssertTrue(try project.include("Greeter/Services/FeedService/Reducers/FeedService.Load.swift", in: app))
        let groups = project.groupPaths
        XCTAssertTrue(groups.values.contains("Greeter/Services/FeedService/Reducers"), "the folders became groups")
        let sources = project.phase("PBXSourcesBuildPhase", of: project.applicationTargets[0])!.list("files")
        XCTAssertEqual(sources.count, 3)
        let text = project.text
        XCTAssertFalse(try project.include("Greeter/Services/FeedService/Reducers/FeedService.Load.swift", in: app))
        XCTAssertEqual(project.text, text)
        XCTAssertEqual(project.folderOfFirstSource(of: project.targets.first { $0.isUnitTests }!.id), "GreeterTests")
        XCTAssertNil(Pbxproj.lint(project.text))
    }

    func testQuotedValuesAndCommentsRead() throws {
        let project = try Pbxproj(ClassicProject.pbxproj)
        let preview = project.objects("PBXGroup").first { $0.string("path") == "Preview Content" }
        XCTAssertNotNil(preview, "a quoted path reads without its quotes")
        let app = project.applicationTargets[0]
        XCTAssertEqual(project.settings(of: app)?["DEVELOPMENT_ASSET_PATHS"]?.string, "\"Greeter/Preview Content\"", "escaped quotes read back")
        XCTAssertEqual(project.moduleName(of: app), "Greeter", "$(TARGET_NAME) is the target's name")
    }
}
