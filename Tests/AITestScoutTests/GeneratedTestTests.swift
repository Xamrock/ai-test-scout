import Foundation
import Testing
@testable import AITestScout

/// Tests for GeneratedTest model - represents a generated test file
@Suite("GeneratedTest Tests")
struct GeneratedTestTests {

    // MARK: - Model Tests

    @Test("GeneratedTest should initialize with required fields")
    func testInitialization() throws {
        let test = GeneratedTest(
            testName: "testLoginFlow",
            code: "func testLoginFlow() { }",
            mode: .flow(screens: ["login", "dashboard"]),
            metadata: TestMetadata(
                screensCovered: ["login", "dashboard"],
                elementsTested: 5,
                estimatedRuntime: 10.5
            )
        )

        #expect(test.testName == "testLoginFlow")
        #expect(test.code.contains("testLoginFlow"))
        #expect(test.metadata.screensCovered.count == 2)
        #expect(test.metadata.elementsTested == 5)
    }

    @Test("GeneratedTest should support different generation modes")
    func testGenerationModes() throws {
        let flowTest = GeneratedTest(
            testName: "testFlow",
            code: "// code",
            mode: .flow(screens: ["screen1", "screen2"]),
            metadata: TestMetadata.empty
        )
        #expect(flowTest.mode.isFlow)

        let screenTest = GeneratedTest(
            testName: "testScreen",
            code: "// code",
            mode: .screen(fingerprint: "screen1"),
            metadata: TestMetadata.empty
        )
        #expect(screenTest.mode.isScreen)

        let fullTest = GeneratedTest(
            testName: "testFull",
            code: "// code",
            mode: .full,
            metadata: TestMetadata.empty
        )
        #expect(fullTest.mode.isFull)
    }

    @Test("GeneratedTest should be Codable")
    func testCodable() throws {
        let original = GeneratedTest(
            testName: "testExample",
            code: "func testExample() { XCTAssert(true) }",
            mode: .flow(screens: ["a", "b"]),
            metadata: TestMetadata(
                screensCovered: ["a", "b"],
                elementsTested: 3,
                estimatedRuntime: 5.0
            )
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GeneratedTest.self, from: data)

        #expect(decoded.testName == original.testName)
        #expect(decoded.code == original.code)
        #expect(decoded.metadata.screensCovered == original.metadata.screensCovered)
    }

    // MARK: - TestMetadata Tests

    @Test("TestMetadata should track coverage information")
    func testMetadataTracking() throws {
        let metadata = TestMetadata(
            screensCovered: ["login", "dashboard", "settings"],
            elementsTested: 12,
            estimatedRuntime: 25.5
        )

        #expect(metadata.screensCovered.count == 3)
        #expect(metadata.elementsTested == 12)
        #expect(metadata.estimatedRuntime == 25.5)
    }

    @Test("TestMetadata should have empty initializer")
    func testMetadataEmpty() throws {
        let empty = TestMetadata.empty

        #expect(empty.screensCovered.isEmpty)
        #expect(empty.elementsTested == 0)
        #expect(empty.estimatedRuntime == 0)
    }

    @Test("TestMetadata should be Codable")
    func testMetadataCodable() throws {
        let original = TestMetadata(
            screensCovered: ["screen1"],
            elementsTested: 5,
            estimatedRuntime: 10.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestMetadata.self, from: data)

        #expect(decoded.screensCovered == original.screensCovered)
        #expect(decoded.elementsTested == original.elementsTested)
    }

    // MARK: - GenerationMode Tests

    @Test("GenerationMode flow should store screen list")
    func testGenerationModeFlow() throws {
        let mode = GenerationMode.flow(screens: ["a", "b", "c"])

        if case .flow(let screens) = mode {
            #expect(screens.count == 3)
            #expect(screens[0] == "a")
        } else {
            #expect(Bool(false), "Should be flow mode")
        }
    }

    @Test("GenerationMode screen should store fingerprint")
    func testGenerationModeScreen() throws {
        let mode = GenerationMode.screen(fingerprint: "screen123")

        if case .screen(let fingerprint) = mode {
            #expect(fingerprint == "screen123")
        } else {
            #expect(Bool(false), "Should be screen mode")
        }
    }

    @Test("GenerationMode should be Codable")
    func testGenerationModeCodable() throws {
        let flowMode = GenerationMode.flow(screens: ["a", "b"])
        let encoder = JSONEncoder()
        let data = try encoder.encode(flowMode)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GenerationMode.self, from: data)

        if case .flow(let screens) = decoded {
            #expect(screens.count == 2)
        } else {
            #expect(Bool(false), "Should decode as flow mode")
        }
    }

    // MARK: - Convenience Properties

    @Test("GeneratedTest should have convenient access to mode details")
    func testModeConvenience() throws {
        let flowTest = GeneratedTest(
            testName: "test",
            code: "//",
            mode: .flow(screens: ["s1", "s2"]),
            metadata: TestMetadata.empty
        )

        #expect(flowTest.mode.isFlow == true)
        #expect(flowTest.mode.isScreen == false)
        #expect(flowTest.mode.isFull == false)
    }

    // MARK: - Real-World Scenarios

    @Test("GeneratedTest should represent a complete test file")
    func testCompleteTestRepresentation() throws {
        let testCode = """
        import XCTest

        final class LoginFlowTests: XCTestCase {
            func testLoginFlow() throws {
                let app = XCUIApplication()
                app.launch()

                let emailField = app.textFields["emailField"]
                XCTAssertTrue(emailField.waitForExistence(timeout: 5))
                emailField.tap()
                emailField.typeText("test@example.com")

                let passwordField = app.secureTextFields["passwordField"]
                passwordField.tap()
                passwordField.typeText("password123")

                let loginButton = app.buttons["loginButton"]
                loginButton.tap()

                XCTAssertTrue(app.staticTexts["Dashboard"].waitForExistence(timeout: 10))
            }
        }
        """

        let test = GeneratedTest(
            testName: "testLoginFlow",
            code: testCode,
            mode: .flow(screens: ["login", "dashboard"]),
            metadata: TestMetadata(
                screensCovered: ["login", "dashboard"],
                elementsTested: 4,
                estimatedRuntime: 15.0
            )
        )

        #expect(test.code.contains("XCUIApplication"))
        #expect(test.code.contains("waitForExistence"))
        #expect(test.metadata.screensCovered.contains("login"))
        #expect(test.metadata.screensCovered.contains("dashboard"))
    }

    @Test("GeneratedTest should track assertions count")
    func testAssertionsTracking() throws {
        var metadata = TestMetadata.empty
        metadata.assertionCount = 5

        let test = GeneratedTest(
            testName: "test",
            code: "// XCTAssertTrue() x5",
            mode: .full,
            metadata: metadata
        )

        #expect(test.metadata.assertionCount == 5)
    }

    @Test("GeneratedTest should track interactions count")
    func testInteractionsTracking() throws {
        var metadata = TestMetadata.empty
        metadata.interactionCount = 8

        let test = GeneratedTest(
            testName: "test",
            code: "// .tap() x8",
            mode: .full,
            metadata: metadata
        )

        #expect(test.metadata.interactionCount == 8)
    }

    // MARK: - Export Tests

    @Test("GeneratedTest should write to file URL")
    func testWriteToFile() throws {
        let test = GeneratedTest(
            testName: "testExample",
            code: "func testExample() { }",
            mode: .flow(screens: ["s1"]),
            metadata: TestMetadata.empty
        )

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GeneratedTest_\(UUID().uuidString).swift")

        try test.writeToFile(url: tempURL)

        #expect(FileManager.default.fileExists(atPath: tempURL.path))

        let content = try String(contentsOf: tempURL)
        #expect(content == test.code)

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("GeneratedTest should generate filename from test name")
    func testFilenameGeneration() throws {
        let test = GeneratedTest(
            testName: "testLoginFlow",
            code: "//",
            mode: .flow(screens: []),
            metadata: TestMetadata.empty
        )

        let filename = test.suggestedFilename
        #expect(filename == "LoginFlowTests.swift")
    }

    @Test("GeneratedTest should handle complex test names for filenames")
    func testComplexFilenameGeneration() throws {
        let test = GeneratedTest(
            testName: "testUserCanLogInAndViewDashboard",
            code: "//",
            mode: .flow(screens: []),
            metadata: TestMetadata.empty
        )

        let filename = test.suggestedFilename
        #expect(filename == "UserCanLogInAndViewDashboardTests.swift")
    }
}
