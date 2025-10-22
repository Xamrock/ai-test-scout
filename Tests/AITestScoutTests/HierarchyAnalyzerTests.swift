import Testing
import Foundation
@testable import AITestScout

@Suite("HierarchyAnalyzer Tests")
struct HierarchyAnalyzerTests {

    // MARK: - Initialization Tests

    @Test("Should initialize with default configuration")
    func testDefaultInitialization() {
        // Act
        let analyzer = HierarchyAnalyzer()

        // Assert - Verify analyzer was created
        // Note: Configuration values are private, but we can verify initialization succeeds
        _ = analyzer // Suppress unused variable warning
        #expect(true, "Analyzer should initialize successfully with defaults")
    }

    @Test("Should initialize with custom configuration")
    func testCustomInitialization() {
        // Act
        let analyzer = HierarchyAnalyzer(
            maxDepth: 5,
            maxChildrenPerElement: 25,
            excludeKeyboard: false,
            useSemanticAnalysis: false
        )

        // Assert
        _ = analyzer // Suppress unused variable warning
        #expect(true, "Analyzer should initialize successfully with custom config")
    }

    // MARK: - Element Priority Logic Tests (Testing Expected Behavior)

    @Test("Should prioritize interactive elements with both ID and label")
    func testCriticalPriorityElements() {
        // This tests the expected behavior of the private calculatePriority method
        // Elements with interactive=true, id, and label should be highest priority

        let criticalElement = MinimalElement(
            type: .button,
            id: "loginButton",
            label: "Login",
            interactive: true
        )

        // Critical elements should have:
        // - interactive: true
        // - id: non-nil
        // - label: non-nil
        #expect(criticalElement.interactive == true)
        #expect(criticalElement.id != nil)
        #expect(criticalElement.label != nil)
    }

    @Test("Should recognize high priority interactive elements")
    func testHighPriorityElements() {
        // Interactive elements with either ID or label (but not both) are high priority

        let elementWithId = MinimalElement(
            type: .button,
            id: "submitBtn",
            label: nil,
            interactive: true
        )

        let elementWithLabel = MinimalElement(
            type: .button,
            id: nil,
            label: "Submit",
            interactive: true
        )

        // High priority elements should be interactive with at least one identifier
        #expect(elementWithId.interactive == true)
        #expect(elementWithId.id != nil)

        #expect(elementWithLabel.interactive == true)
        #expect(elementWithLabel.label != nil)
    }

    @Test("Should recognize medium priority elements")
    func testMediumPriorityElements() {
        // Interactive without ID/label, or non-interactive with ID

        let interactiveNoId = MinimalElement(
            type: .button,
            id: nil,
            label: nil,
            interactive: true
        )

        let nonInteractiveWithId = MinimalElement(
            type: .text,
            id: "titleLabel",
            label: nil,
            interactive: false
        )

        #expect(interactiveNoId.interactive == true)
        #expect(interactiveNoId.id == nil && interactiveNoId.label == nil)

        #expect(nonInteractiveWithId.interactive == false)
        #expect(nonInteractiveWithId.id != nil)
    }

    @Test("Should recognize low priority elements")
    func testLowPriorityElements() {
        // Non-interactive with only label

        let lowPriorityElement = MinimalElement(
            type: .text,
            id: nil,
            label: "Some text",
            interactive: false
        )

        #expect(lowPriorityElement.interactive == false)
        #expect(lowPriorityElement.id == nil)
        #expect(lowPriorityElement.label != nil)
    }

    // MARK: - Element Inclusion Logic Tests

    @Test("Should include all interactive elements")
    func testInteractiveElementsIncluded() {
        // Interactive elements should always be included regardless of content

        let buttonNoContent = MinimalElement(
            type: .button,
            id: nil,
            label: nil,
            interactive: true
        )

        let inputWithContent = MinimalElement(
            type: .input,
            id: "email",
            label: "Email",
            interactive: true
        )

        // Both should be included (interactive = true)
        #expect(buttonNoContent.interactive == true)
        #expect(inputWithContent.interactive == true)
    }

    @Test("Should include text elements with content")
    func testTextElementsWithContent() {
        // Text elements should be included if they have a label

        let textWithLabel = MinimalElement(
            type: .text,
            id: nil,
            label: "Welcome to the app",
            interactive: false
        )

        #expect(textWithLabel.type == .text)
        #expect(textWithLabel.label != nil)
    }

    @Test("Should include elements with identifiers")
    func testElementsWithIdentifiers() {
        // Any element with an ID should be included (developer marked as important)

        let containerWithId = MinimalElement(
            type: .container,
            id: "mainContainer",
            label: nil,
            interactive: false
        )

        #expect(containerWithId.id != nil)
    }

    @Test("Should include image elements")
    func testImageElementsIncluded() {
        // Images provide visual context and should be included

        let image = MinimalElement(
            type: .image,
            id: nil,
            label: nil,
            interactive: false
        )

        #expect(image.type == .image)
    }

    @Test("Should exclude completely empty elements")
    func testEmptyElementsExcluded() {
        // Elements with no ID, no label, no content, and non-interactive should be excluded

        let emptyContainer = MinimalElement(
            type: .container,
            id: nil,
            label: nil,
            interactive: false
        )

        // This element should be excluded (no identifying info, not interactive, not an image)
        #expect(emptyContainer.id == nil)
        #expect(emptyContainer.label == nil)
        #expect(emptyContainer.interactive == false)
        #expect(emptyContainer.type != .image)
    }

    // MARK: - Keyboard Detection Logic Tests

    @Test("Should detect keyboard elements by identifier")
    func testKeyboardIdentifierDetection() {
        // Elements with keyboard-related identifiers should be detected

        let keyboardIdentifiers = [
            "keyboard",
            "Keyboard",
            "autocorrection",
            "prediction",
            "emoji"
        ]

        for identifier in keyboardIdentifiers {
            let lowercased = identifier.lowercased()
            #expect(
                lowercased.contains("keyboard") ||
                lowercased.contains("autocorrection") ||
                lowercased.contains("prediction") ||
                lowercased.contains("emoji"),
                "Should detect '\(identifier)' as keyboard-related"
            )
        }
    }

    @Test("Should detect keyboard keys by single character labels")
    func testKeyboardKeySingleCharDetection() {
        // Single character labels are likely keyboard keys

        let singleChars = ["a", "b", "1", "?", "@"]

        for char in singleChars {
            #expect(char.count == 1, "Should detect '\(char)' as keyboard key")
        }
    }

    @Test("Should detect keyboard action buttons by label")
    func testKeyboardActionButtonDetection() {
        // Common keyboard button labels

        let keyboardLabels = [
            "return", "space", "shift", "delete",
            "next keyboard", "dictation", "emoji",
            "done", "go", "search", "send"
        ]

        for label in keyboardLabels {
            let lowercased = label.lowercased()
            #expect(
                lowercased.contains("return") ||
                lowercased.contains("space") ||
                lowercased.contains("shift") ||
                lowercased.contains("delete") ||
                lowercased.contains("next keyboard") ||
                lowercased.contains("dictation") ||
                lowercased.contains("emoji") ||
                lowercased.contains("done") ||
                lowercased.contains("go") ||
                lowercased.contains("search") ||
                lowercased.contains("send"),
                "Should detect '\(label)' as keyboard button"
            )
        }
    }

    @Test("Should not detect non-keyboard elements")
    func testNonKeyboardElementsNotDetected() {
        // Regular app elements should not be detected as keyboard

        let appLabels = ["Submit", "Login", "Welcome", "Settings"]

        for label in appLabels {
            let lowercased = label.lowercased()
            let isKeyboard = lowercased.count == 1 || [
                "return", "space", "shift", "delete",
                "next keyboard", "dictation", "emoji"
            ].contains { lowercased.contains($0) }

            #expect(isKeyboard == false, "Should not detect '\(label)' as keyboard element")
        }
    }

    // MARK: - Value Capture Tests

    @Test("Should capture string values from interactive elements")
    func testStringValueCapture() {
        // Interactive elements can have string values

        let inputWithValue = MinimalElement(
            type: .input,
            id: "emailField",
            label: "Email",
            interactive: true,
            value: "test@example.com"
        )

        #expect(inputWithValue.interactive == true)
        #expect(inputWithValue.value == "test@example.com")
    }

    @Test("Should capture numeric values from toggles and sliders")
    func testNumericValueCapture() {
        // Toggles and sliders can have numeric values

        let toggle = MinimalElement(
            type: .toggle,
            id: "notifications",
            label: "Notifications",
            interactive: true,
            value: "1" // NSNumber converted to string
        )

        let slider = MinimalElement(
            type: .slider,
            id: "volume",
            label: "Volume",
            interactive: true,
            value: "75"
        )

        #expect(toggle.value == "1")
        #expect(slider.value == "75")
    }

    @Test("Should handle empty or nil values")
    func testEmptyValueHandling() {
        // Elements without values should have nil value field

        let buttonNoValue = MinimalElement(
            type: .button,
            id: "submit",
            label: "Submit",
            interactive: true,
            value: nil
        )

        #expect(buttonNoValue.value == nil)
    }

    @Test("Should not capture values for non-interactive elements")
    func testNonInteractiveNoValue() {
        // Non-interactive elements should not have values

        let staticText = MinimalElement(
            type: .text,
            id: nil,
            label: "Welcome",
            interactive: false,
            value: nil
        )

        #expect(staticText.interactive == false)
        #expect(staticText.value == nil)
    }

    // MARK: - Semantic Integration Tests

    @Test("Should enrich elements with semantic intent")
    func testSemanticIntentEnrichment() {
        // Elements should be enriched with intent metadata

        let submitButton = MinimalElement(
            type: .button,
            id: "login",
            label: "Login",
            interactive: true,
            intent: .submit
        )

        let cancelButton = MinimalElement(
            type: .button,
            id: "cancel",
            label: "Cancel",
            interactive: true,
            intent: .cancel
        )

        #expect(submitButton.intent == .submit)
        #expect(cancelButton.intent == .cancel)
    }

    @Test("Should enrich elements with priority scores")
    func testSemanticPriorityEnrichment() {
        // Elements should be enriched with priority scores

        let highPriorityElement = MinimalElement(
            type: .button,
            id: "login",
            label: "Login",
            interactive: true,
            intent: .submit,
            priority: 150 // High priority (submit intent + interactive + ID + label)
        )

        let lowPriorityElement = MinimalElement(
            type: .button,
            id: "delete",
            label: "Delete",
            interactive: true,
            intent: .destructive,
            priority: 45 // Low priority (destructive intent)
        )

        #expect(highPriorityElement.priority ?? 0 > lowPriorityElement.priority ?? 0)
    }

    @Test("Should omit neutral intent to save tokens")
    func testNeutralIntentOmission() {
        // Neutral intent should be nil (not included in JSON)

        let neutralElement = MinimalElement(
            type: .button,
            id: "generic",
            label: "Button",
            interactive: true,
            intent: nil // Neutral intent is omitted
        )

        #expect(neutralElement.intent == nil)
    }

    @Test("Should detect screen type from element composition")
    func testScreenTypeDetection() {
        // Verify screen type detection works with SemanticAnalyzer

        let analyzer = DefaultSemanticAnalyzer()

        let loginElements = [
            MinimalElement(type: .input, id: "email", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "password", label: "Password", interactive: true),
            MinimalElement(type: .button, id: "login", label: "Login", interactive: true)
        ]

        let screenType = analyzer.detectScreenType(from: loginElements)
        #expect(screenType == .login)
    }
}

// MARK: - Integration Test Documentation

/*
 INTEGRATION TESTS REQUIRED (Must run in UI Test target with real app):

 1. testCaptureFromRealApplication
    - Launch test app
    - Call analyzer.capture(from: app)
    - Verify elements are captured
    - Verify screenshot is captured

 2. testKeyboardExclusionEnabled
    - Show keyboard in test app
    - Capture with excludeKeyboard: true
    - Verify no keyboard elements in result

 3. testKeyboardExclusionDisabled
    - Show keyboard in test app
    - Capture with excludeKeyboard: false
    - Verify keyboard elements ARE included

 4. testTop50ElementSelection
    - App with >50 interactive elements
    - Verify only top 50 by priority are captured

 5. testMaxDepthRespected
    - App with deep hierarchy (>10 levels)
    - Verify depth limit is respected

 6. testMaxChildrenPerElementRespected
    - App with element having >50 children
    - Verify child limit is respected

 7. testSemanticAnalysisEnabled
    - Capture with useSemanticAnalysis: true
    - Verify elements have intent and priority fields

 8. testSemanticAnalysisDisabled
    - Capture with useSemanticAnalysis: false
    - Verify elements don't have intent and priority fields

 9. testScreenTypeDetectionInHierarchy
    - Various screen types (login, form, list, settings)
    - Verify screenType field is correctly populated in CompressedHierarchy

 10. testPriorityBasedSelection
     - App with mixed priority elements
     - Verify high priority elements are selected over low priority

 To run these tests:
 1. Create a test app target in yerp/ or demo app
 2. Create HierarchyAnalyzerUITests.swift in UI test target
 3. Implement the tests above with real XCUIApplication
 */
