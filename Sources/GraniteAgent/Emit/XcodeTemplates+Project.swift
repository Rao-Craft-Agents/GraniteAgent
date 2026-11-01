//  WHAT: The project file template: objects named by tokens (`@@APP_IOS@@`), names and identifiers by placeholders,
//        tabs as Xcode writes them. `XcodeTemplates.project` fills it.

import Foundation

extension XcodeTemplates {
    static let projectTemplate = """
        // !$*UTF8*$!
        {
        \tarchiveVersion = 1;
        \tclasses = {
        \t};
        \tobjectVersion = 77;
        \tobjects = {
        
        /* Begin PBXContainerItemProxy section */
        \t\t@@PROXY_TESTS_IOS@@ /* PBXContainerItemProxy */ = {
        \t\t\tisa = PBXContainerItemProxy;
        \t\t\tcontainerPortal = @@PROJECT@@ /* Project object */;
        \t\t\tproxyType = 1;
        \t\t\tremoteGlobalIDString = @@APP_IOS@@;
        \t\t\tremoteInfo = "@@NAME@@-iOS";
        \t\t};
        \t\t@@PROXY_TESTS_MAC@@ /* PBXContainerItemProxy */ = {
        \t\t\tisa = PBXContainerItemProxy;
        \t\t\tcontainerPortal = @@PROJECT@@ /* Project object */;
        \t\t\tproxyType = 1;
        \t\t\tremoteGlobalIDString = @@APP_MAC@@;
        \t\t\tremoteInfo = "@@NAME@@-macOS";
        \t\t};
        \t\t@@PROXY_UITESTS_IOS@@ /* PBXContainerItemProxy */ = {
        \t\t\tisa = PBXContainerItemProxy;
        \t\t\tcontainerPortal = @@PROJECT@@ /* Project object */;
        \t\t\tproxyType = 1;
        \t\t\tremoteGlobalIDString = @@APP_IOS@@;
        \t\t\tremoteInfo = "@@NAME@@-iOS";
        \t\t};
        \t\t@@PROXY_UITESTS_MAC@@ /* PBXContainerItemProxy */ = {
        \t\t\tisa = PBXContainerItemProxy;
        \t\t\tcontainerPortal = @@PROJECT@@ /* Project object */;
        \t\t\tproxyType = 1;
        \t\t\tremoteGlobalIDString = @@APP_MAC@@;
        \t\t\tremoteInfo = "@@NAME@@-macOS";
        \t\t};
        /* End PBXContainerItemProxy section */
        
        /* Begin PBXFileReference section */
        \t\t@@PRODUCT_APP_IOS@@ /* @@NAME@@.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = @@NAME@@.app; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\t@@PRODUCT_APP_MAC@@ /* @@NAME@@.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = @@NAME@@.app; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\t@@PRODUCT_TESTS_IOS@@ /* @@NAME@@Tests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = @@NAME@@Tests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\t@@PRODUCT_TESTS_MAC@@ /* @@NAME@@Tests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = @@NAME@@Tests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\t@@PRODUCT_UITESTS_IOS@@ /* @@NAME@@UITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = @@NAME@@UITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\t@@PRODUCT_UITESTS_MAC@@ /* @@NAME@@UITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = @@NAME@@UITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        /* End PBXFileReference section */
        
        /* Begin PBXFileSystemSynchronizedRootGroup section */
        \t\t@@SYNC_SHARED@@ /* Shared */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = Shared;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@SYNC_COMPONENTS@@ /* Components */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = Components;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@SYNC_SERVICES@@ /* Services */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = Services;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@SYNC_IOS@@ /* iOS */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = iOS;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@SYNC_MACOS@@ /* macOS */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = macOS;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@SYNC_TESTS@@ /* Tests */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = Tests;
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@SYNC_UITESTS@@ /* UITests */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = UITests;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXFileSystemSynchronizedRootGroup section */
        
        /* Begin PBXFrameworksBuildPhase section */
        \t\t@@FW_APP_IOS@@ /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@FW_APP_MAC@@ /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@FW_TESTS_IOS@@ /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@FW_TESTS_MAC@@ /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@FW_UITESTS_IOS@@ /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@FW_UITESTS_MAC@@ /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXFrameworksBuildPhase section */
        
        /* Begin PBXGroup section */
        \t\t@@MAIN@@ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\t@@SYNC_SHARED@@ /* Shared */,
        \t\t\t\t@@SYNC_COMPONENTS@@ /* Components */,
        \t\t\t\t@@SYNC_SERVICES@@ /* Services */,
        \t\t\t\t@@SYNC_IOS@@ /* iOS */,
        \t\t\t\t@@SYNC_MACOS@@ /* macOS */,
        \t\t\t\t@@SYNC_TESTS@@ /* Tests */,
        \t\t\t\t@@SYNC_UITESTS@@ /* UITests */,
        \t\t\t\t@@PRODUCTS@@ /* Products */,
        \t\t\t);
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t@@PRODUCTS@@ /* Products */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\t@@PRODUCT_APP_IOS@@ /* @@NAME@@.app */,
        \t\t\t\t@@PRODUCT_APP_MAC@@ /* @@NAME@@.app */,
        \t\t\t\t@@PRODUCT_TESTS_IOS@@ /* @@NAME@@Tests.xctest */,
        \t\t\t\t@@PRODUCT_TESTS_MAC@@ /* @@NAME@@Tests.xctest */,
        \t\t\t\t@@PRODUCT_UITESTS_IOS@@ /* @@NAME@@UITests.xctest */,
        \t\t\t\t@@PRODUCT_UITESTS_MAC@@ /* @@NAME@@UITests.xctest */,
        \t\t\t);
        \t\t\tname = Products;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXGroup section */
        
        /* Begin PBXNativeTarget section */
        \t\t@@APP_IOS@@ /* @@NAME@@-iOS */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = @@LIST_APP_IOS@@ /* Build configuration list for PBXNativeTarget "@@NAME@@-iOS" */;
        \t\t\tbuildPhases = (
        \t\t\t\t@@SRC_APP_IOS@@ /* Sources */,
        \t\t\t\t@@FW_APP_IOS@@ /* Frameworks */,
        \t\t\t\t@@RES_APP_IOS@@ /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\t@@SYNC_SHARED@@ /* Shared */,
        \t\t\t\t@@SYNC_COMPONENTS@@ /* Components */,
        \t\t\t\t@@SYNC_SERVICES@@ /* Services */,
        \t\t\t\t@@SYNC_IOS@@ /* iOS */,
        \t\t\t);
        \t\t\tname = "@@NAME@@-iOS";
        \t\t\tpackageProductDependencies = (
        \t\t\t);
        \t\t\tproductName = @@NAME@@;
        \t\t\tproductReference = @@PRODUCT_APP_IOS@@ /* @@NAME@@.app */;
        \t\t\tproductType = "com.apple.product-type.application";
        \t\t};
        \t\t@@APP_MAC@@ /* @@NAME@@-macOS */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = @@LIST_APP_MAC@@ /* Build configuration list for PBXNativeTarget "@@NAME@@-macOS" */;
        \t\t\tbuildPhases = (
        \t\t\t\t@@SRC_APP_MAC@@ /* Sources */,
        \t\t\t\t@@FW_APP_MAC@@ /* Frameworks */,
        \t\t\t\t@@RES_APP_MAC@@ /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\t@@SYNC_SHARED@@ /* Shared */,
        \t\t\t\t@@SYNC_COMPONENTS@@ /* Components */,
        \t\t\t\t@@SYNC_SERVICES@@ /* Services */,
        \t\t\t\t@@SYNC_MACOS@@ /* macOS */,
        \t\t\t);
        \t\t\tname = "@@NAME@@-macOS";
        \t\t\tpackageProductDependencies = (
        \t\t\t);
        \t\t\tproductName = @@NAME@@;
        \t\t\tproductReference = @@PRODUCT_APP_MAC@@ /* @@NAME@@.app */;
        \t\t\tproductType = "com.apple.product-type.application";
        \t\t};
        \t\t@@TESTS_IOS@@ /* @@NAME@@Tests-iOS */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = @@LIST_TESTS_IOS@@ /* Build configuration list for PBXNativeTarget "@@NAME@@Tests-iOS" */;
        \t\t\tbuildPhases = (
        \t\t\t\t@@SRC_TESTS_IOS@@ /* Sources */,
        \t\t\t\t@@FW_TESTS_IOS@@ /* Frameworks */,
        \t\t\t\t@@RES_TESTS_IOS@@ /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t\t@@DEP_TESTS_IOS@@ /* PBXTargetDependency */,
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\t@@SYNC_TESTS@@ /* Tests */,
        \t\t\t);
        \t\t\tname = "@@NAME@@Tests-iOS";
        \t\t\tpackageProductDependencies = (
        \t\t\t);
        \t\t\tproductName = @@NAME@@Tests;
        \t\t\tproductReference = @@PRODUCT_TESTS_IOS@@ /* @@NAME@@Tests.xctest */;
        \t\t\tproductType = "com.apple.product-type.bundle.unit-test";
        \t\t};
        \t\t@@TESTS_MAC@@ /* @@NAME@@Tests-macOS */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = @@LIST_TESTS_MAC@@ /* Build configuration list for PBXNativeTarget "@@NAME@@Tests-macOS" */;
        \t\t\tbuildPhases = (
        \t\t\t\t@@SRC_TESTS_MAC@@ /* Sources */,
        \t\t\t\t@@FW_TESTS_MAC@@ /* Frameworks */,
        \t\t\t\t@@RES_TESTS_MAC@@ /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t\t@@DEP_TESTS_MAC@@ /* PBXTargetDependency */,
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\t@@SYNC_TESTS@@ /* Tests */,
        \t\t\t);
        \t\t\tname = "@@NAME@@Tests-macOS";
        \t\t\tpackageProductDependencies = (
        \t\t\t);
        \t\t\tproductName = @@NAME@@Tests;
        \t\t\tproductReference = @@PRODUCT_TESTS_MAC@@ /* @@NAME@@Tests.xctest */;
        \t\t\tproductType = "com.apple.product-type.bundle.unit-test";
        \t\t};
        \t\t@@UITESTS_IOS@@ /* @@NAME@@UITests-iOS */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = @@LIST_UITESTS_IOS@@ /* Build configuration list for PBXNativeTarget "@@NAME@@UITests-iOS" */;
        \t\t\tbuildPhases = (
        \t\t\t\t@@SRC_UITESTS_IOS@@ /* Sources */,
        \t\t\t\t@@FW_UITESTS_IOS@@ /* Frameworks */,
        \t\t\t\t@@RES_UITESTS_IOS@@ /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t\t@@DEP_UITESTS_IOS@@ /* PBXTargetDependency */,
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\t@@SYNC_UITESTS@@ /* UITests */,
        \t\t\t);
        \t\t\tname = "@@NAME@@UITests-iOS";
        \t\t\tpackageProductDependencies = (
        \t\t\t);
        \t\t\tproductName = @@NAME@@UITests;
        \t\t\tproductReference = @@PRODUCT_UITESTS_IOS@@ /* @@NAME@@UITests.xctest */;
        \t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
        \t\t};
        \t\t@@UITESTS_MAC@@ /* @@NAME@@UITests-macOS */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = @@LIST_UITESTS_MAC@@ /* Build configuration list for PBXNativeTarget "@@NAME@@UITests-macOS" */;
        \t\t\tbuildPhases = (
        \t\t\t\t@@SRC_UITESTS_MAC@@ /* Sources */,
        \t\t\t\t@@FW_UITESTS_MAC@@ /* Frameworks */,
        \t\t\t\t@@RES_UITESTS_MAC@@ /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t\t@@DEP_UITESTS_MAC@@ /* PBXTargetDependency */,
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\t@@SYNC_UITESTS@@ /* UITests */,
        \t\t\t);
        \t\t\tname = "@@NAME@@UITests-macOS";
        \t\t\tpackageProductDependencies = (
        \t\t\t);
        \t\t\tproductName = @@NAME@@UITests;
        \t\t\tproductReference = @@PRODUCT_UITESTS_MAC@@ /* @@NAME@@UITests.xctest */;
        \t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
        \t\t};
        /* End PBXNativeTarget section */
        
        /* Begin PBXProject section */
        \t\t@@PROJECT@@ /* Project object */ = {
        \t\t\tisa = PBXProject;
        \t\t\tattributes = {
        \t\t\t\tBuildIndependentTargetsInParallel = 1;
        \t\t\t\tLastSwiftUpdateCheck = 2660;
        \t\t\t\tLastUpgradeCheck = 2660;
        \t\t\t\tTargetAttributes = {
        \t\t\t\t\t@@APP_IOS@@ = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.0;
        \t\t\t\t\t};
        \t\t\t\t\t@@APP_MAC@@ = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.0;
        \t\t\t\t\t};
        \t\t\t\t\t@@TESTS_IOS@@ = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.0;
        \t\t\t\t\t\tTestTargetID = @@APP_IOS@@;
        \t\t\t\t\t};
        \t\t\t\t\t@@TESTS_MAC@@ = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.0;
        \t\t\t\t\t\tTestTargetID = @@APP_MAC@@;
        \t\t\t\t\t};
        \t\t\t\t\t@@UITESTS_IOS@@ = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.0;
        \t\t\t\t\t\tTestTargetID = @@APP_IOS@@;
        \t\t\t\t\t};
        \t\t\t\t\t@@UITESTS_MAC@@ = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.0;
        \t\t\t\t\t\tTestTargetID = @@APP_MAC@@;
        \t\t\t\t\t};
        \t\t\t\t};
        \t\t\t};
        \t\t\tbuildConfigurationList = @@LIST_PROJECT@@ /* Build configuration list for PBXProject "@@NAME@@" */;
        \t\t\tdevelopmentRegion = en;
        \t\t\thasScannedForEncodings = 0;
        \t\t\tknownRegions = (
        \t\t\t\ten,
        \t\t\t\tBase,
        \t\t\t);
        \t\t\tmainGroup = @@MAIN@@;
        \t\t\tminimizedProjectReferenceProxies = 1;
        \t\t\tpackageReferences = (
        \t\t\t);
        \t\t\tpreferredProjectObjectVersion = 77;
        \t\t\tproductRefGroup = @@PRODUCTS@@ /* Products */;
        \t\t\tprojectDirPath = "";
        \t\t\tprojectRoot = "";
        \t\t\ttargets = (
        \t\t\t\t@@APP_IOS@@ /* @@NAME@@-iOS */,
        \t\t\t\t@@APP_MAC@@ /* @@NAME@@-macOS */,
        \t\t\t\t@@TESTS_IOS@@ /* @@NAME@@Tests-iOS */,
        \t\t\t\t@@TESTS_MAC@@ /* @@NAME@@Tests-macOS */,
        \t\t\t\t@@UITESTS_IOS@@ /* @@NAME@@UITests-iOS */,
        \t\t\t\t@@UITESTS_MAC@@ /* @@NAME@@UITests-macOS */,
        \t\t\t);
        \t\t};
        /* End PBXProject section */
        
        /* Begin PBXResourcesBuildPhase section */
        \t\t@@RES_APP_IOS@@ /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@RES_APP_MAC@@ /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@RES_TESTS_IOS@@ /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@RES_TESTS_MAC@@ /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@RES_UITESTS_IOS@@ /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@RES_UITESTS_MAC@@ /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXResourcesBuildPhase section */
        
        /* Begin PBXSourcesBuildPhase section */
        \t\t@@SRC_APP_IOS@@ /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@SRC_APP_MAC@@ /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@SRC_TESTS_IOS@@ /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@SRC_TESTS_MAC@@ /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@SRC_UITESTS_IOS@@ /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        \t\t@@SRC_UITESTS_MAC@@ /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXSourcesBuildPhase section */
        
        /* Begin PBXTargetDependency section */
        \t\t@@DEP_TESTS_IOS@@ /* PBXTargetDependency */ = {
        \t\t\tisa = PBXTargetDependency;
        \t\t\ttarget = @@APP_IOS@@ /* @@NAME@@-iOS */;
        \t\t\ttargetProxy = @@PROXY_TESTS_IOS@@ /* PBXContainerItemProxy */;
        \t\t};
        \t\t@@DEP_TESTS_MAC@@ /* PBXTargetDependency */ = {
        \t\t\tisa = PBXTargetDependency;
        \t\t\ttarget = @@APP_MAC@@ /* @@NAME@@-macOS */;
        \t\t\ttargetProxy = @@PROXY_TESTS_MAC@@ /* PBXContainerItemProxy */;
        \t\t};
        \t\t@@DEP_UITESTS_IOS@@ /* PBXTargetDependency */ = {
        \t\t\tisa = PBXTargetDependency;
        \t\t\ttarget = @@APP_IOS@@ /* @@NAME@@-iOS */;
        \t\t\ttargetProxy = @@PROXY_UITESTS_IOS@@ /* PBXContainerItemProxy */;
        \t\t};
        \t\t@@DEP_UITESTS_MAC@@ /* PBXTargetDependency */ = {
        \t\t\tisa = PBXTargetDependency;
        \t\t\ttarget = @@APP_MAC@@ /* @@NAME@@-macOS */;
        \t\t\ttargetProxy = @@PROXY_UITESTS_MAC@@ /* PBXContainerItemProxy */;
        \t\t};
        /* End PBXTargetDependency section */
        
        /* Begin XCBuildConfiguration section */
        \t\t@@CFG_PROJECT_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tCLANG_ANALYZER_NONNULL = YES;
        \t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
        \t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
        \t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
        \t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_COMMA = YES;
        \t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
        \t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
        \t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
        \t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
        \t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
        \t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
        \t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
        \t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
        \t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
        \t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
        \t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
        \t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
        \t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
        \t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
        \t\t\t\tCOPY_PHASE_STRIP = NO;
        \t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
        \t\t\t\tENABLE_TESTABILITY = YES;
        \t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
        \t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
        \t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
        \t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
        \t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
        \t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
        \t\t\t\t\t"DEBUG=1",
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t);
        \t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
        \t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
        \t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
        \t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
        \t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
        \t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
        \t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
        \t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
        \t\t\t\tMTL_FAST_MATH = YES;
        \t\t\t\tONLY_ACTIVE_ARCH = YES;
        \t\t\t\tSDKROOT = auto;
        \t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
        \t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_PROJECT_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tCLANG_ANALYZER_NONNULL = YES;
        \t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
        \t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
        \t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
        \t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_COMMA = YES;
        \t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
        \t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
        \t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
        \t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
        \t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
        \t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
        \t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
        \t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
        \t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
        \t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
        \t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
        \t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
        \t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
        \t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
        \t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
        \t\t\t\tCOPY_PHASE_STRIP = NO;
        \t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tENABLE_NS_ASSERTIONS = NO;
        \t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
        \t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
        \t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
        \t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
        \t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
        \t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
        \t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
        \t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
        \t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
        \t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
        \t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
        \t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
        \t\t\t\tMTL_FAST_MATH = YES;
        \t\t\t\tSDKROOT = auto;
        \t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t@@CFG_APP_IOS_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = @@DISPLAY@@;
        \t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        \t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
        \t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t\t"@executable_path/Frameworks",
        \t\t\t\t);
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME_Q@@;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
        \t\t\t\tSUPPORTS_MACCATALYST = NO;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_APP_IOS_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = @@DISPLAY@@;
        \t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        \t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
        \t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t\t"@executable_path/Frameworks",
        \t\t\t\t);
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME_Q@@;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
        \t\t\t\tSUPPORTS_MACCATALYST = NO;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tVALIDATE_PRODUCT = YES;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t@@CFG_APP_MAC_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tENABLE_APP_SANDBOX = YES;
        \t\t\t\tENABLE_HARDENED_RUNTIME = YES;
        \t\t\t\tENABLE_OUTGOING_NETWORK_CONNECTIONS = YES;
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tENABLE_USER_SELECTED_FILES = readonly;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = @@DISPLAY@@;
        \t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t\t"@executable_path/../Frameworks",
        \t\t\t\t);
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME_Q@@;
        \t\t\t\tSDKROOT = macosx;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_APP_MAC_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tENABLE_APP_SANDBOX = YES;
        \t\t\t\tENABLE_HARDENED_RUNTIME = YES;
        \t\t\t\tENABLE_OUTGOING_NETWORK_CONNECTIONS = YES;
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tENABLE_USER_SELECTED_FILES = readonly;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = @@DISPLAY@@;
        \t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t\t"@executable_path/../Frameworks",
        \t\t\t\t);
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME_Q@@;
        \t\t\t\tSDKROOT = macosx;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tVALIDATE_PRODUCT = YES;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t@@CFG_TESTS_IOS_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@TESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@Tests;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/@@NAME@@.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/@@NAME@@";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_TESTS_IOS_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@TESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@Tests;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/@@NAME@@.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/@@NAME@@";
        \t\t\t\tVALIDATE_PRODUCT = YES;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t@@CFG_TESTS_MAC_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@TESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@Tests;
        \t\t\t\tSDKROOT = macosx;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/@@NAME@@.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/@@NAME@@";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_TESTS_MAC_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@TESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@Tests;
        \t\t\t\tSDKROOT = macosx;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/@@NAME@@.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/@@NAME@@";
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t@@CFG_UITESTS_IOS_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@UITESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@UITests;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tTEST_TARGET_NAME = "@@NAME@@-iOS";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_UITESTS_IOS_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@UITESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@UITests;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t\tTEST_TARGET_NAME = "@@NAME@@-iOS";
        \t\t\t\tVALIDATE_PRODUCT = YES;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t@@CFG_UITESTS_MAC_DEBUG@@ /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@UITESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@UITests;
        \t\t\t\tSDKROOT = macosx;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTEST_TARGET_NAME = "@@NAME@@-macOS";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t@@CFG_UITESTS_MAC_RELEASE@@ /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tDEVELOPMENT_TEAM = @@TEAM@@;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = @@UITESTS_BUNDLE@@;
        \t\t\t\tPRODUCT_NAME = @@NAME@@UITests;
        \t\t\t\tSDKROOT = macosx;
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTEST_TARGET_NAME = "@@NAME@@-macOS";
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        /* End XCBuildConfiguration section */
        
        /* Begin XCConfigurationList section */
        \t\t@@LIST_PROJECT@@ /* Build configuration list for PBXProject "@@NAME@@" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_PROJECT_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_PROJECT_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t@@LIST_APP_IOS@@ /* Build configuration list for PBXNativeTarget "@@NAME@@-iOS" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_APP_IOS_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_APP_IOS_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t@@LIST_APP_MAC@@ /* Build configuration list for PBXNativeTarget "@@NAME@@-macOS" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_APP_MAC_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_APP_MAC_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t@@LIST_TESTS_IOS@@ /* Build configuration list for PBXNativeTarget "@@NAME@@Tests-iOS" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_TESTS_IOS_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_TESTS_IOS_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t@@LIST_TESTS_MAC@@ /* Build configuration list for PBXNativeTarget "@@NAME@@Tests-macOS" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_TESTS_MAC_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_TESTS_MAC_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t@@LIST_UITESTS_IOS@@ /* Build configuration list for PBXNativeTarget "@@NAME@@UITests-iOS" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_UITESTS_IOS_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_UITESTS_IOS_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t@@LIST_UITESTS_MAC@@ /* Build configuration list for PBXNativeTarget "@@NAME@@UITests-macOS" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t@@CFG_UITESTS_MAC_DEBUG@@ /* Debug */,
        \t\t\t\t@@CFG_UITESTS_MAC_RELEASE@@ /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        /* End XCConfigurationList section */
        \t};
        \trootObject = @@PROJECT@@ /* Project object */;
        }
        
        """
}
