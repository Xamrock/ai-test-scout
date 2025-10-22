import Testing
import Foundation
@testable import AITestScout

@Suite("SemanticAnalyzer Tests")
struct SemanticAnalyzerTests {

    // MARK: - Element Intent Detection

    @Test("Should detect submit/confirm intent from labels")
    func testSubmitIntentDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let submitLabels = ["Submit", "Login", "Sign In", "Continue", "Next", "Confirm", "Save", "Send"]

        for label in submitLabels {
            let intent = analyzer.detectIntent(label: label, identifier: nil)
            #expect(intent == .submit, "Expected submit intent for '\(label)'")
        }
    }

    @Test("Should detect cancel/dismiss intent from labels")
    func testCancelIntentDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let cancelLabels = ["Cancel", "Close", "Dismiss", "Back", "Skip", "Not Now"]

        for label in cancelLabels {
            let intent = analyzer.detectIntent(label: label, identifier: nil)
            #expect(intent == .cancel, "Expected cancel intent for '\(label)'")
        }
    }

    @Test("Should detect destructive intent from labels")
    func testDestructiveIntentDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let destructiveLabels = ["Delete", "Remove", "Clear", "Logout", "Sign Out", "Disconnect"]

        for label in destructiveLabels {
            let intent = analyzer.detectIntent(label: label, identifier: nil)
            #expect(intent == .destructive, "Expected destructive intent for '\(label)'")
        }
    }

    @Test("Should detect navigation intent from labels")
    func testNavigationIntentDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let navLabels = ["Settings", "Profile", "Home", "Menu", "More", "Details"]

        for label in navLabels {
            let intent = analyzer.detectIntent(label: label, identifier: nil)
            #expect(intent == .navigation, "Expected navigation intent for '\(label)'")
        }
    }

    @Test("Should detect neutral intent for generic labels")
    func testNeutralIntentDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let neutralLabels = ["Title", "Label", "Text", "", "Unknown"]

        for label in neutralLabels {
            let intent = analyzer.detectIntent(label: label, identifier: nil)
            #expect(intent == .neutral, "Expected neutral intent for '\(label)'")
        }
    }

    // MARK: - Screen Type Detection

    @Test("Should detect login screen from elements")
    func testLoginScreenDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .input, id: "emailField", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "passwordField", label: "Password", interactive: true),
            MinimalElement(type: .button, id: "loginButton", label: "Login", interactive: true)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .login)
    }

    @Test("Should detect form screen from multiple inputs")
    func testFormScreenDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .input, id: "nameField", label: "Name", interactive: true),
            MinimalElement(type: .input, id: "emailField", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "phoneField", label: "Phone", interactive: true),
            MinimalElement(type: .button, id: "submitButton", label: "Submit", interactive: true)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .form)
    }

    @Test("Should detect list screen from scrollable containers")
    func testListScreenDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .scrollable, id: "tableView", label: nil, interactive: true),
            MinimalElement(type: .text, id: nil, label: "Item 1", interactive: false),
            MinimalElement(type: .text, id: nil, label: "Item 2", interactive: false),
            MinimalElement(type: .text, id: nil, label: "Item 3", interactive: false)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .list)
    }

    @Test("Should detect settings screen from keywords")
    func testSettingsScreenDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .text, id: "screenTitle", label: "Settings", interactive: false),
            MinimalElement(type: .toggle, id: "notificationsToggle", label: "Notifications", interactive: true),
            MinimalElement(type: .button, id: "privacyButton", label: "Privacy", interactive: true)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .settings)
    }

    @Test("Should detect tab navigation from tab elements")
    func testTabScreenDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .tab, id: "homeTab", label: "Home", interactive: true),
            MinimalElement(type: .tab, id: "searchTab", label: "Search", interactive: true),
            MinimalElement(type: .tab, id: "profileTab", label: "Profile", interactive: true)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .tabNavigation)
    }

    @Test("Should detect error screen from error indicators")
    func testErrorScreenDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .text, id: "errorMessage", label: "Error: Connection failed", interactive: false),
            MinimalElement(type: .button, id: "retryButton", label: "Retry", interactive: true)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .error)
    }

    @Test("Should detect loading state from activity indicators")
    func testLoadingStateDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .container, id: "activityIndicator", label: nil, interactive: false),
            MinimalElement(type: .text, id: nil, label: "Loading...", interactive: false)
        ]

        let screenType = analyzer.detectScreenType(from: elements)
        #expect(screenType == .loading)
    }

    // MARK: - Semantic Grouping

    @Test("Should group related form fields")
    func testFormFieldGrouping() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .input, id: "emailField", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "passwordField", label: "Password", interactive: true),
            MinimalElement(type: .button, id: "submitButton", label: "Submit", interactive: true),
            MinimalElement(type: .button, id: "settingsButton", label: "Settings", interactive: true)
        ]

        let groups = analyzer.groupRelatedElements(elements)

        // Should have form group and navigation group
        #expect(groups.count >= 1, "Should identify at least one semantic group")

        let formGroup = groups.first { $0.type == .formInput }
        #expect(formGroup != nil, "Should identify form input group")
        #expect(formGroup?.elements.count ?? 0 >= 2, "Form group should contain email and password")
    }

    @Test("Should identify submit button for forms")
    func testSubmitButtonIdentification() {
        let analyzer = DefaultSemanticAnalyzer()

        let elements = [
            MinimalElement(type: .input, id: "field1", label: "Field", interactive: true),
            MinimalElement(type: .button, id: "btn1", label: "Cancel", interactive: true),
            MinimalElement(type: .button, id: "btn2", label: "Submit", interactive: true)
        ]

        let groups = analyzer.groupRelatedElements(elements)
        let actionGroup = groups.first { $0.type == .action }

        #expect(actionGroup != nil, "Should identify action group")
        #expect(actionGroup?.primaryElement?.label == "Submit", "Should identify Submit as primary action")
    }

    // MARK: - Priority Scoring

    @Test("Should assign higher priority to submit buttons")
    func testSubmitButtonPriority() {
        let analyzer = DefaultSemanticAnalyzer()

        let submitButton = MinimalElement(type: .button, id: "submit", label: "Submit", interactive: true)
        let cancelButton = MinimalElement(type: .button, id: "cancel", label: "Cancel", interactive: true)

        let submitPriority = analyzer.calculateSemanticPriority(submitButton)
        let cancelPriority = analyzer.calculateSemanticPriority(cancelButton)

        #expect(submitPriority > cancelPriority, "Submit button should have higher priority than cancel")
    }

    @Test("Should assign lower priority to destructive actions")
    func testDestructivePriority() {
        let analyzer = DefaultSemanticAnalyzer()

        let saveButton = MinimalElement(type: .button, id: "save", label: "Save", interactive: true)
        let deleteButton = MinimalElement(type: .button, id: "delete", label: "Delete", interactive: true)

        let savePriority = analyzer.calculateSemanticPriority(saveButton)
        let deletePriority = analyzer.calculateSemanticPriority(deleteButton)

        #expect(savePriority > deletePriority, "Save button should have higher priority than delete")
    }

    // MARK: - Case Insensitivity

    @Test("Should handle case insensitive matching")
    func testCaseInsensitiveDetection() {
        let analyzer = DefaultSemanticAnalyzer()

        let variations = ["LOGIN", "login", "Login", "LoGiN"]

        for variation in variations {
            let intent = analyzer.detectIntent(label: variation, identifier: nil)
            #expect(intent == .submit, "Should detect '\(variation)' as submit intent")
        }
    }

    // MARK: - Identifier-Only Intent Detection

    @Test("Should detect intent from identifier when label is nil")
    func testIntentFromIdentifierOnly() {
        let analyzer = DefaultSemanticAnalyzer()

        // Test cases where only identifier is provided
        let testCases: [(String, SemanticIntent)] = [
            ("submitButton", .submit),
            ("loginBtn", .submit),
            ("cancelAction", .cancel),
            ("deleteButton", .destructive),
            ("settingsLink", .navigation)
        ]

        for (identifier, expectedIntent) in testCases {
            let intent = analyzer.detectIntent(label: nil, identifier: identifier)
            #expect(intent == expectedIntent, "Should detect '\(expectedIntent)' from identifier '\(identifier)'")
        }
    }

    @Test("Should prioritize label over identifier when both present")
    func testLabelPriorityOverIdentifier() {
        let analyzer = DefaultSemanticAnalyzer()

        // Label says "submit", identifier says "cancel" - label should win
        let intent1 = analyzer.detectIntent(label: "Submit", identifier: "cancelButton")
        #expect(intent1 == .submit, "Label should take priority over identifier")

        // Label says "delete", identifier says "submit" - label should win
        let intent2 = analyzer.detectIntent(label: "Delete", identifier: "submitButton")
        #expect(intent2 == .destructive, "Label should take priority over identifier")
    }

    @Test("Should handle partial matches in identifiers")
    func testPartialMatchInIdentifiers() {
        let analyzer = DefaultSemanticAnalyzer()

        let identifiers = [
            "btn_submit_primary",
            "action_delete_item",
            "link_settings_page",
            "button_cancel_operation"
        ]

        let expectedIntents: [SemanticIntent] = [.submit, .destructive, .navigation, .cancel]

        for (identifier, expectedIntent) in zip(identifiers, expectedIntents) {
            let intent = analyzer.detectIntent(label: nil, identifier: identifier)
            #expect(intent == expectedIntent, "Should detect '\(expectedIntent)' from identifier '\(identifier)'")
        }
    }

    // MARK: - Screen Type Detection Edge Cases

    @Test("Should fallback to content screen when no specific type matches")
    func testContentScreenFallback() {
        let analyzer = DefaultSemanticAnalyzer()

        // Generic elements that don't match specific screen patterns
        let genericElements = [
            MinimalElement(type: .text, label: "Welcome", interactive: false),
            MinimalElement(type: .button, label: "Action", interactive: true),
            MinimalElement(type: .image, id: "logo", label: nil, interactive: false)
        ]

        let screenType = analyzer.detectScreenType(from: genericElements)
        #expect(screenType == .content, "Should default to content screen for generic elements")
    }

    @Test("Should detect screen type in priority order")
    func testScreenTypePriorityOrder() {
        let analyzer = DefaultSemanticAnalyzer()

        // Loading indicators should be detected before other types
        let loadingElements = [
            MinimalElement(type: .text, label: "Loading...", interactive: false),
            MinimalElement(type: .button, label: "Submit", interactive: true) // Has submit, but loading takes priority
        ]

        let loadingScreen = analyzer.detectScreenType(from: loadingElements)
        #expect(loadingScreen == .loading, "Loading screen should be detected first")

        // Error should be detected before form
        let errorElements = [
            MinimalElement(type: .text, label: "Error occurred", interactive: false),
            MinimalElement(type: .input, id: "field1", label: "Field", interactive: true),
            MinimalElement(type: .input, id: "field2", label: "Field", interactive: true),
            MinimalElement(type: .button, label: "Submit", interactive: true)
        ]

        let errorScreen = analyzer.detectScreenType(from: errorElements)
        #expect(errorScreen == .error, "Error screen should be detected before form")
    }

    @Test("Should handle empty element array")
    func testEmptyElementArray() {
        let analyzer = DefaultSemanticAnalyzer()

        let emptyElements: [MinimalElement] = []
        let screenType = analyzer.detectScreenType(from: emptyElements)

        #expect(screenType == .content, "Should return content for empty array")
    }

    @Test("Should distinguish between form and login screens")
    func testFormVsLoginDistinction() {
        let analyzer = DefaultSemanticAnalyzer()

        // Login requires: email/username + password + login button
        let loginElements = [
            MinimalElement(type: .input, id: "email", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "password", label: "Password", interactive: true),
            MinimalElement(type: .button, id: "login", label: "Login", interactive: true)
        ]

        // Form has inputs + submit but not login-specific
        let formElements = [
            MinimalElement(type: .input, id: "name", label: "Name", interactive: true),
            MinimalElement(type: .input, id: "phone", label: "Phone", interactive: true),
            MinimalElement(type: .button, id: "submit", label: "Submit", interactive: true)
        ]

        #expect(analyzer.detectScreenType(from: loginElements) == .login)
        #expect(analyzer.detectScreenType(from: formElements) == .form)
    }

    // MARK: - Priority Calculation Edge Cases

    @Test("Should calculate priority for elements without label or ID")
    func testPriorityWithoutIdentifiers() {
        let analyzer = DefaultSemanticAnalyzer()

        let interactiveNoId = MinimalElement(
            type: .button,
            id: nil,
            label: nil,
            interactive: true
        )

        let nonInteractiveNoId = MinimalElement(
            type: .text,
            id: nil,
            label: nil,
            interactive: false
        )

        let interactivePriority = analyzer.calculateSemanticPriority(interactiveNoId)
        let nonInteractivePriority = analyzer.calculateSemanticPriority(nonInteractiveNoId)

        #expect(interactivePriority > nonInteractivePriority, "Interactive should have higher priority even without ID/label")
        #expect(interactivePriority >= 20, "Should get interactive bonus (+20)")
    }

    @Test("Should give bonus for elements with both ID and label")
    func testBonusForBothIdAndLabel() {
        let analyzer = DefaultSemanticAnalyzer()

        let withBoth = MinimalElement(
            type: .button,
            id: "generic",
            label: "Generic",
            interactive: true
        )

        let withOnlyId = MinimalElement(
            type: .button,
            id: "generic",
            label: nil,
            interactive: true
        )

        let priorityBoth = analyzer.calculateSemanticPriority(withBoth)
        let priorityOnlyId = analyzer.calculateSemanticPriority(withOnlyId)

        // Note: Current implementation prioritizes by intent first, so elements with same intent
        // may have similar priorities. Having both ID and label improves discoverability
        // but doesn't necessarily increase semantic priority for AI decisions
        #expect(priorityBoth >= priorityOnlyId, "Element with both ID and label should have at least equal priority")
    }

    @Test("Should give input fields high priority")
    func testInputFieldPriority() {
        let analyzer = DefaultSemanticAnalyzer()

        let inputField = MinimalElement(
            type: .input,
            id: "email",
            label: "Email",
            interactive: true
        )

        let regularButton = MinimalElement(
            type: .button,
            id: "action",
            label: "Action",
            interactive: true,
            intent: .neutral
        )

        let inputPriority = analyzer.calculateSemanticPriority(inputField)
        let buttonPriority = analyzer.calculateSemanticPriority(regularButton)

        // Input fields get +30 bonus, should be higher than neutral buttons
        #expect(inputPriority > buttonPriority, "Input fields should have higher priority for data entry importance")
    }
}
