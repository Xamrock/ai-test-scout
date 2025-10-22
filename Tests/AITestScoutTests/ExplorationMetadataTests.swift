import Foundation
import Testing
import CoreGraphics
@testable import AITestScout

/// Tests for ExplorationMetadata and AppContext - Metadata enrichment for LLM test generation
@Suite("ExplorationMetadata Tests")
struct ExplorationMetadataTests {

    // MARK: - AppContext Tests

    @Test("AppContext initializes with all fields")
    func testAppContextInitialization() throws {
        let appContext = AppContext(
            bundleId: "com.example.app",
            appVersion: "1.2.3",
            buildNumber: "456",
            launchArguments: ["-UITest", "-DisableAnimations"],
            launchEnvironment: ["UITEST_MODE": "1", "DEBUG": "true"]
        )

        #expect(appContext.bundleId == "com.example.app")
        #expect(appContext.appVersion == "1.2.3")
        #expect(appContext.buildNumber == "456")
        #expect(appContext.launchArguments.count == 2)
        #expect(appContext.launchEnvironment.count == 2)
    }

    @Test("AppContext with minimal initialization")
    func testAppContextMinimal() throws {
        let appContext = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "1"
        )

        #expect(appContext.bundleId == "com.test.app")
        #expect(appContext.launchArguments.isEmpty)
        #expect(appContext.launchEnvironment.isEmpty)
    }

    @Test("AppContext is Equatable")
    func testAppContextEquatable() throws {
        let context1 = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "100"
        )

        let context2 = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "100"
        )

        #expect(context1 == context2)
    }

    @Test("AppContext is Codable")
    func testAppContextCodable() throws {
        let original = AppContext(
            bundleId: "com.example.app",
            appVersion: "2.0.0",
            buildNumber: "200",
            launchArguments: ["-UITest"],
            launchEnvironment: ["TEST": "true"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppContext.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - ExplorationMetadata Tests

    @Test("ExplorationMetadata initializes with all components")
    func testExplorationMetadataInitialization() throws {
        let environment = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone 15 Pro",
            screenResolution: CGSize(width: 393, height: 852),
            orientation: "portrait",
            locale: "en_US"
        )

        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")
        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let appContext = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "1"
        )

        let metadata = ExplorationMetadata(
            environment: environment,
            elementContexts: ["button|btn|Button": context],
            appContext: appContext
        )

        #expect(metadata.environment.platform == "iOS")
        #expect(metadata.elementContexts.count == 1)
        #expect(metadata.appContext.bundleId == "com.test.app")
    }

    @Test("ExplorationMetadata with multiple element contexts")
    func testExplorationMetadataMultipleContexts() throws {
        let environment = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone",
            screenResolution: CGSize(width: 390, height: 844),
            orientation: "portrait",
            locale: "en_US"
        )

        let queries1 = ElementQueries(primary: "app.buttons[\"loginBtn\"]")
        let context1 = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries1
        )

        let queries2 = ElementQueries(primary: "app.textFields[\"emailField\"]")
        let context2 = ElementContext(
            xcuiElementType: "XCUIElementTypeTextField",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries2
        )

        let appContext = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "1"
        )

        let metadata = ExplorationMetadata(
            environment: environment,
            elementContexts: [
                "button|loginBtn|Login": context1,
                "input|emailField|Email": context2
            ],
            appContext: appContext
        )

        #expect(metadata.elementContexts.count == 2)
        #expect(metadata.elementContexts["button|loginBtn|Login"] != nil)
        #expect(metadata.elementContexts["input|emailField|Email"] != nil)
    }

    @Test("ExplorationMetadata is Equatable")
    func testExplorationMetadataEquatable() throws {
        let environment = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone",
            screenResolution: CGSize(width: 390, height: 844),
            orientation: "portrait",
            locale: "en_US"
        )

        let appContext = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "1"
        )

        let metadata1 = ExplorationMetadata(
            environment: environment,
            elementContexts: [:],
            appContext: appContext
        )

        let metadata2 = ExplorationMetadata(
            environment: environment,
            elementContexts: [:],
            appContext: appContext
        )

        #expect(metadata1 == metadata2)
    }

    @Test("ExplorationMetadata is Codable")
    func testExplorationMetadataCodable() throws {
        let environment = EnvironmentInfo(
            platform: "macOS",
            osVersion: "14.0",
            deviceModel: "Mac",
            screenResolution: CGSize(width: 1920, height: 1080),
            orientation: "landscape",
            locale: "en_US"
        )

        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")
        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let appContext = AppContext(
            bundleId: "com.example.app",
            appVersion: "2.5.0",
            buildNumber: "250"
        )

        let original = ExplorationMetadata(
            environment: environment,
            elementContexts: ["button|btn|Button": context],
            appContext: appContext
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExplorationMetadata.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Element Context Lookup

    @Test("ExplorationMetadata element context lookup by key")
    func testElementContextLookup() throws {
        let environment = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone",
            screenResolution: CGSize.zero,
            orientation: "portrait",
            locale: "en_US"
        )

        let queries = ElementQueries(primary: "app.buttons[\"submitBtn\"]")
        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let appContext = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "1"
        )

        let metadata = ExplorationMetadata(
            environment: environment,
            elementContexts: ["button|submitBtn|Submit": context],
            appContext: appContext
        )

        let foundContext = metadata.elementContexts["button|submitBtn|Submit"]
        #expect(foundContext != nil)
        #expect(foundContext?.xcuiElementType == "XCUIElementTypeButton")
    }

    // MARK: - Real World Scenarios

    @Test("ExplorationMetadata for login screen test")
    func testLoginScreenMetadata() throws {
        let environment = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone 15 Pro",
            screenResolution: CGSize(width: 393, height: 852),
            orientation: "portrait",
            locale: "en_US"
        )

        // Email field
        let emailQueries = ElementQueries(
            primary: "app.textFields[\"emailField\"]",
            byLabel: "app.textFields[\"Email\"]"
        )
        let emailContext = ElementContext(
            xcuiElementType: "XCUIElementTypeTextField",
            frame: CGRect(x: 20, y: 200, width: 353, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: emailQueries
        )

        // Password field
        let passwordQueries = ElementQueries(
            primary: "app.secureTextFields[\"passwordField\"]",
            byLabel: "app.secureTextFields[\"Password\"]"
        )
        let passwordContext = ElementContext(
            xcuiElementType: "XCUIElementTypeSecureTextField",
            frame: CGRect(x: 20, y: 260, width: 353, height: 44),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: passwordQueries
        )

        // Login button
        let loginQueries = ElementQueries(
            primary: "app.buttons[\"loginButton\"]",
            byLabel: "app.buttons[\"Log In\"]"
        )
        let loginContext = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect(x: 20, y: 700, width: 353, height: 50),
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: loginQueries
        )

        let appContext = AppContext(
            bundleId: "com.example.myapp",
            appVersion: "1.0.0",
            buildNumber: "100",
            launchArguments: ["-UITest", "-DisableAnimations"],
            launchEnvironment: ["UITEST_MODE": "1"]
        )

        let metadata = ExplorationMetadata(
            environment: environment,
            elementContexts: [
                "input|emailField|Email": emailContext,
                "input|passwordField|Password": passwordContext,
                "button|loginButton|Log In": loginContext
            ],
            appContext: appContext
        )

        #expect(metadata.elementContexts.count == 3)
        #expect(metadata.appContext.launchArguments.contains("-UITest"))
        #expect(metadata.environment.deviceModel.contains("iPhone"))
    }

    // MARK: - JSON Export

    @Test("ExplorationMetadata exports to structured JSON")
    func testMetadataJSONExport() throws {
        let environment = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone",
            screenResolution: CGSize(width: 390, height: 844),
            orientation: "portrait",
            locale: "en_US"
        )

        let queries = ElementQueries(primary: "app.buttons[\"btn\"]")
        let context = ElementContext(
            xcuiElementType: "XCUIElementTypeButton",
            frame: CGRect.zero,
            isEnabled: true,
            isVisible: true,
            isHittable: true,
            hasFocus: false,
            queries: queries
        )

        let appContext = AppContext(
            bundleId: "com.test.app",
            appVersion: "1.0.0",
            buildNumber: "1"
        )

        let metadata = ExplorationMetadata(
            environment: environment,
            elementContexts: ["button|btn|Button": context],
            appContext: appContext
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(metadata)

        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString != nil)
        #expect(jsonString?.contains("environment") == true)
        #expect(jsonString?.contains("elementContexts") == true)
        #expect(jsonString?.contains("appContext") == true)
    }
}
