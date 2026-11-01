//  A fresh Xcode "App" project in classic groups (objectVersion 56, one multiplatform app target, a hosted unit-test
//  target, Swift 6): what `make: link` is held to bringing Granite into.

import Foundation

enum ClassicProject {
    /// Writes the project into `folder`: Greeter.xcodeproj, its app, its assets and its tests.
    static func write(to folder: URL) throws {
        let files: [(String, String)] = [
            ("Greeter.xcodeproj/project.pbxproj", pbxproj),
            ("Greeter.xcodeproj/project.xcworkspace/contents.xcworkspacedata", workspace),
            ("Greeter/GreeterApp.swift", app),
            ("Greeter/ContentView.swift", contentView),
            ("Greeter/Greeter.entitlements", entitlements),
            ("Greeter/Assets.xcassets/Contents.json", assets),
            ("Greeter/Assets.xcassets/AccentColor.colorset/Contents.json", accent),
            ("Greeter/Assets.xcassets/AppIcon.appiconset/Contents.json", icon),
            ("Greeter/Preview Content/Preview Assets.xcassets/Contents.json", assets),
            ("GreeterTests/GreeterTests.swift", tests),
        ]
        for (path, text) in files {
            let url = folder.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    static let pbxproj = """
        // !$*UTF8*$!
        {
        \tarchiveVersion = 1;
        \tclasses = {
        \t};
        \tobjectVersion = 56;
        \tobjects = {
        
        /* Begin PBXBuildFile section */
        \t\tA10000000000000000000001 /* GreeterApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000001 /* GreeterApp.swift */; };
        \t\tA10000000000000000000002 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000002 /* ContentView.swift */; };
        \t\tA10000000000000000000003 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000003 /* Assets.xcassets */; };
        \t\tA10000000000000000000004 /* Preview Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000004 /* Preview Assets.xcassets */; };
        \t\tA10000000000000000000005 /* GreeterTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20000000000000000000005 /* GreeterTests.swift */; };
        /* End PBXBuildFile section */
        
        /* Begin PBXContainerItemProxy section */
        \t\tA30000000000000000000001 /* PBXContainerItemProxy */ = {
        \t\t\tisa = PBXContainerItemProxy;
        \t\t\tcontainerPortal = A90000000000000000000001 /* Project object */;
        \t\t\tproxyType = 1;
        \t\t\tremoteGlobalIDString = A80000000000000000000001;
        \t\t\tremoteInfo = Greeter;
        \t\t};
        /* End PBXContainerItemProxy section */
        
        /* Begin PBXFileReference section */
        \t\tA20000000000000000000000 /* Greeter.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Greeter.app; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\tA20000000000000000000001 /* GreeterApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GreeterApp.swift; sourceTree = "<group>"; };
        \t\tA20000000000000000000002 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
        \t\tA20000000000000000000003 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
        \t\tA20000000000000000000004 /* Preview Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; };
        \t\tA20000000000000000000005 /* GreeterTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GreeterTests.swift; sourceTree = "<group>"; };
        \t\tA20000000000000000000006 /* GreeterTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = GreeterTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\tA20000000000000000000007 /* Greeter.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Greeter.entitlements; sourceTree = "<group>"; };
        /* End PBXFileReference section */
        
        /* Begin PBXFrameworksBuildPhase section */
        \t\tA40000000000000000000001 /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\tA40000000000000000000002 /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXFrameworksBuildPhase section */
        
        /* Begin PBXGroup section */
        \t\tA50000000000000000000001 = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA50000000000000000000002 /* Greeter */,
        \t\t\t\tA50000000000000000000004 /* GreeterTests */,
        \t\t\t\tA50000000000000000000005 /* Products */,
        \t\t\t);
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\tA50000000000000000000002 /* Greeter */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA20000000000000000000001 /* GreeterApp.swift */,
        \t\t\t\tA20000000000000000000002 /* ContentView.swift */,
        \t\t\t\tA20000000000000000000003 /* Assets.xcassets */,
        \t\t\t\tA20000000000000000000007 /* Greeter.entitlements */,
        \t\t\t\tA50000000000000000000003 /* Preview Content */,
        \t\t\t);
        \t\t\tpath = Greeter;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\tA50000000000000000000003 /* Preview Content */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA20000000000000000000004 /* Preview Assets.xcassets */,
        \t\t\t);
        \t\t\tpath = "Preview Content";
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\tA50000000000000000000004 /* GreeterTests */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA20000000000000000000005 /* GreeterTests.swift */,
        \t\t\t);
        \t\t\tpath = GreeterTests;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\tA50000000000000000000005 /* Products */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA20000000000000000000000 /* Greeter.app */,
        \t\t\t\tA20000000000000000000006 /* GreeterTests.xctest */,
        \t\t\t);
        \t\t\tname = Products;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXGroup section */
        
        /* Begin PBXNativeTarget section */
        \t\tA80000000000000000000001 /* Greeter */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = AB0000000000000000000002 /* Build configuration list for PBXNativeTarget "Greeter" */;
        \t\t\tbuildPhases = (
        \t\t\t\tA60000000000000000000001 /* Sources */,
        \t\t\t\tA40000000000000000000001 /* Frameworks */,
        \t\t\t\tA70000000000000000000001 /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t);
        \t\t\tname = Greeter;
        \t\t\tproductName = Greeter;
        \t\t\tproductReference = A20000000000000000000000 /* Greeter.app */;
        \t\t\tproductType = "com.apple.product-type.application";
        \t\t};
        \t\tA80000000000000000000002 /* GreeterTests */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = AB0000000000000000000003 /* Build configuration list for PBXNativeTarget "GreeterTests" */;
        \t\t\tbuildPhases = (
        \t\t\t\tA60000000000000000000002 /* Sources */,
        \t\t\t\tA40000000000000000000002 /* Frameworks */,
        \t\t\t\tA70000000000000000000002 /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t\tAC0000000000000000000001 /* PBXTargetDependency */,
        \t\t\t);
        \t\t\tname = GreeterTests;
        \t\t\tproductName = GreeterTests;
        \t\t\tproductReference = A20000000000000000000006 /* GreeterTests.xctest */;
        \t\t\tproductType = "com.apple.product-type.bundle.unit-test";
        \t\t};
        /* End PBXNativeTarget section */
        
        /* Begin PBXProject section */
        \t\tA90000000000000000000001 /* Project object */ = {
        \t\t\tisa = PBXProject;
        \t\t\tattributes = {
        \t\t\t\tBuildIndependentTargetsInParallel = 1;
        \t\t\t\tLastSwiftUpdateCheck = 1500;
        \t\t\t\tLastUpgradeCheck = 1500;
        \t\t\t\tTargetAttributes = {
        \t\t\t\t\tA80000000000000000000001 = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
        \t\t\t\t\t};
        \t\t\t\t\tA80000000000000000000002 = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
        \t\t\t\t\t\tTestTargetID = A80000000000000000000001;
        \t\t\t\t\t};
        \t\t\t\t};
        \t\t\t};
        \t\t\tbuildConfigurationList = AB0000000000000000000001 /* Build configuration list for PBXProject "Greeter" */;
        \t\t\tcompatibilityVersion = "Xcode 14.0";
        \t\t\tdevelopmentRegion = en;
        \t\t\thasScannedForEncodings = 0;
        \t\t\tknownRegions = (
        \t\t\t\ten,
        \t\t\t\tBase,
        \t\t\t);
        \t\t\tmainGroup = A50000000000000000000001;
        \t\t\tproductRefGroup = A50000000000000000000005 /* Products */;
        \t\t\tprojectDirPath = "";
        \t\t\tprojectRoot = "";
        \t\t\ttargets = (
        \t\t\t\tA80000000000000000000001 /* Greeter */,
        \t\t\t\tA80000000000000000000002 /* GreeterTests */,
        \t\t\t);
        \t\t};
        /* End PBXProject section */
        
        /* Begin PBXResourcesBuildPhase section */
        \t\tA70000000000000000000001 /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t\tA10000000000000000000004 /* Preview Assets.xcassets in Resources */,
        \t\t\t\tA10000000000000000000003 /* Assets.xcassets in Resources */,
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\tA70000000000000000000002 /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXResourcesBuildPhase section */
        
        /* Begin PBXSourcesBuildPhase section */
        \t\tA60000000000000000000001 /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t\tA10000000000000000000002 /* ContentView.swift in Sources */,
        \t\t\t\tA10000000000000000000001 /* GreeterApp.swift in Sources */,
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\tA60000000000000000000002 /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t\tA10000000000000000000005 /* GreeterTests.swift in Sources */,
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXSourcesBuildPhase section */
        
        /* Begin PBXTargetDependency section */
        \t\tAC0000000000000000000001 /* PBXTargetDependency */ = {
        \t\t\tisa = PBXTargetDependency;
        \t\t\ttarget = A80000000000000000000001 /* Greeter */;
        \t\t\ttargetProxy = A30000000000000000000001 /* PBXContainerItemProxy */;
        \t\t};
        /* End PBXTargetDependency section */
        
        /* Begin XCBuildConfiguration section */
        \t\tAD0000000000000000000001 /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
        \t\t\t\tCLANG_ANALYZER_NONNULL = YES;
        \t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
        \t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
        \t\t\t\tCOPY_PHASE_STRIP = NO;
        \t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
        \t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
        \t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
        \t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
        \t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
        \t\t\t\tMTL_FAST_MATH = YES;
        \t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
        \t\t\t\tENABLE_TESTABILITY = YES;
        \t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
        \t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
        \t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
        \t\t\t\t\t"DEBUG=1",
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t);
        \t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
        \t\t\t\tONLY_ACTIVE_ARCH = YES;
        \t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
        \t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\tAD0000000000000000000002 /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
        \t\t\t\tCLANG_ANALYZER_NONNULL = YES;
        \t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
        \t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
        \t\t\t\tCOPY_PHASE_STRIP = NO;
        \t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
        \t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
        \t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
        \t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
        \t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
        \t\t\t\tMTL_FAST_MATH = YES;
        \t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
        \t\t\t\tENABLE_NS_ASSERTIONS = NO;
        \t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
        \t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\tAD0000000000000000000003 /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_ENTITLEMENTS = Greeter/Greeter.entitlements;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_ASSET_PATHS = "\\"Greeter/Preview Content\\"";
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\t"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*]" = YES;
        \t\t\t\t"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphonesimulator*]" = YES;
        \t\t\t\t"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*]" = YES;
        \t\t\t\t"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphonesimulator*]" = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = "@executable_path/Frameworks";
        \t\t\t\t"LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]" = "@executable_path/../Frameworks";
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.Greeter;
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSDKROOT = auto;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 6.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\tAD0000000000000000000004 /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_ENTITLEMENTS = Greeter/Greeter.entitlements;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_ASSET_PATHS = "\\"Greeter/Preview Content\\"";
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\t"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*]" = YES;
        \t\t\t\t"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphonesimulator*]" = YES;
        \t\t\t\t"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*]" = YES;
        \t\t\t\t"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphonesimulator*]" = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = "@executable_path/Frameworks";
        \t\t\t\t"LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]" = "@executable_path/../Frameworks";
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.Greeter;
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSDKROOT = auto;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 6.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\tAD0000000000000000000005 /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.GreeterTests;
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSDKROOT = auto;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 6.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Greeter.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Greeter";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\tAD0000000000000000000006 /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.GreeterTests;
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSDKROOT = auto;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 6.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Greeter.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Greeter";
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        /* End XCBuildConfiguration section */
        
        /* Begin XCConfigurationList section */
        \t\tAB0000000000000000000001 /* Build configuration list for PBXProject "Greeter" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\tAD0000000000000000000001 /* Debug */,
        \t\t\t\tAD0000000000000000000002 /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\tAB0000000000000000000002 /* Build configuration list for PBXNativeTarget "Greeter" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\tAD0000000000000000000003 /* Debug */,
        \t\t\t\tAD0000000000000000000004 /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\tAB0000000000000000000003 /* Build configuration list for PBXNativeTarget "GreeterTests" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\tAD0000000000000000000005 /* Debug */,
        \t\t\t\tAD0000000000000000000006 /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        /* End XCConfigurationList section */
        \t};
        \trootObject = A90000000000000000000001 /* Project object */;
        }
        
        """

    static let workspace = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace
           version = "1.0">
           <FileRef
              location = "self:">
           </FileRef>
        </Workspace>

        """

    static let app = """
        import SwiftUI

        @main
        struct GreeterApp: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
            }
        }

        """

    static let contentView = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                }
                .padding()
            }
        }

        #Preview {
            ContentView()
        }

        """

    static let entitlements = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>com.apple.security.app-sandbox</key>
            <true/>
            <key>com.apple.security.files.user-selected.read-only</key>
            <true/>
        </dict>
        </plist>

        """

    static let assets = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """

    static let accent = """
        {
          "colors" : [
            {
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """

    static let icon = """
        {
          "images" : [
            { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
            { "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
            { "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """

    static let tests = """
        import Testing
        @testable import Greeter

        struct GreeterTests {
            @Test func example() async throws {
            }
        }

        """
}
