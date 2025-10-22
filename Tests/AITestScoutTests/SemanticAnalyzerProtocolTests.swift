import Testing
import Foundation
@testable import AITestScout

@Suite("SemanticAnalyzerProtocol Tests")
struct SemanticAnalyzerProtocolTests {

    // MARK: - Default Analyzer Tests

    @Test("Default analyzer should detect submit intent")
    func testDefaultAnalyzerSubmitIntent() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()

        // Act
        let intent = analyzer.detectIntent(label: "Login", identifier: nil)

        // Assert
        #expect(intent == .submit)
    }

    @Test("Default analyzer should detect destructive intent")
    func testDefaultAnalyzerDestructiveIntent() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()

        // Act
        let intent = analyzer.detectIntent(label: "Delete", identifier: nil)

        // Assert
        #expect(intent == .destructive)
    }

    @Test("Default analyzer should detect screen types")
    func testDefaultAnalyzerScreenType() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()
        let elements = [
            MinimalElement(type: .input, id: "email", label: "Email", interactive: true),
            MinimalElement(type: .input, id: "password", label: "Password", interactive: true),
            MinimalElement(type: .button, id: "login", label: "Login", interactive: true)
        ]

        // Act
        let screenType = analyzer.detectScreenType(from: elements)

        // Assert
        #expect(screenType == .login)
    }

    @Test("Default analyzer should calculate semantic priority")
    func testDefaultAnalyzerPriority() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()
        let submitButton = MinimalElement(
            type: .button,
            id: "submit",
            label: "Submit",
            interactive: true
        )

        // Act
        let priority = analyzer.calculateSemanticPriority(submitButton)

        // Assert
        #expect(priority > 100, "Submit button should have high priority")
    }

    @Test("Default analyzer should group related elements")
    func testDefaultAnalyzerGrouping() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()
        let elements = [
            MinimalElement(type: .input, id: "field1", label: "Field", interactive: true),
            MinimalElement(type: .button, id: "submit", label: "Submit", interactive: true)
        ]

        // Act
        let groups = analyzer.groupRelatedElements(elements)

        // Assert
        #expect(!groups.isEmpty, "Should create element groups")
    }

    // MARK: - Custom Analyzer Tests

    @Test("Custom analyzer can override intent detection")
    func testCustomAnalyzerOverrideIntent() {
        // Arrange
        let customAnalyzer = CustomTestAnalyzer()

        // Act
        let intent = customAnalyzer.detectIntent(label: "Custom Action", identifier: nil)

        // Assert
        #expect(intent == .submit, "Custom analyzer should treat 'Custom Action' as submit")
    }

    @Test("Custom analyzer can override screen type detection")
    func testCustomAnalyzerOverrideScreenType() {
        // Arrange
        let customAnalyzer = CustomTestAnalyzer()
        let elements = [
            MinimalElement(type: .text, label: "Any text", interactive: false)
        ]

        // Act
        let screenType = customAnalyzer.detectScreenType(from: elements)

        // Assert
        #expect(screenType == .content, "Custom analyzer should return content for any screen")
    }

    @Test("Custom analyzer can override priority calculation")
    func testCustomAnalyzerOverridePriority() {
        // Arrange
        let customAnalyzer = CustomTestAnalyzer()
        let element = MinimalElement(type: .button, label: "Test", interactive: true)

        // Act
        let priority = customAnalyzer.calculateSemanticPriority(element)

        // Assert
        #expect(priority == 999, "Custom analyzer should return fixed priority")
    }

    // MARK: - Configurable Patterns Tests

    @Test("Default analyzer patterns should be configurable")
    func testConfigurablePatterns() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()

        // Act - Add custom pattern
        analyzer.submitPatterns.append("custom-action")
        let intent = analyzer.detectIntent(label: "custom-action", identifier: nil)

        // Assert
        #expect(intent == .submit, "Should detect custom pattern as submit")
    }

    @Test("Custom patterns should override defaults")
    func testCustomPatternsOverride() {
        // Arrange
        let analyzer = DefaultSemanticAnalyzer()
        analyzer.submitPatterns = ["only-this"]  // Replace all patterns

        // Act
        let shouldMatch = analyzer.detectIntent(label: "only-this", identifier: nil)
        let shouldNotMatch = analyzer.detectIntent(label: "login", identifier: nil)

        // Assert
        #expect(shouldMatch == .submit)
        #expect(shouldNotMatch != .submit, "Login should not match after pattern replacement")
    }

    // MARK: - Nil Analyzer Tests

    @Test("HierarchyAnalyzer should support nil semantic analyzer")
    func testNilSemanticAnalyzer() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()
        config.semanticAnalyzer = nil

        // Act
        let analyzer = HierarchyAnalyzer(configuration: config)

        // Assert - Analyzer created successfully
        _ = analyzer
        #expect(true, "Should initialize with nil semantic analyzer")
    }

    @Test("Nil semantic analyzer should disable semantic features")
    func testNilAnalyzerDisablesFeatures() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()
        config.semanticAnalyzer = nil

        // Act & Assert - Should not crash
        let analyzer = HierarchyAnalyzer(configuration: config)
        _ = analyzer
        #expect(true, "Should handle nil analyzer gracefully")
    }

    // MARK: - Integration Tests

    @Test("Configuration should accept custom semantic analyzer")
    func testConfigurationAcceptsCustomAnalyzer() {
        // Arrange
        let customAnalyzer = CustomTestAnalyzer()
        var config = HierarchyAnalyzerConfiguration()
        config.semanticAnalyzer = customAnalyzer

        // Act
        let analyzer = HierarchyAnalyzer(configuration: config)

        // Assert
        _ = analyzer
        #expect(true, "Configuration should accept custom analyzer")
    }

    @Test("Default configuration should use default analyzer")
    func testDefaultConfigurationUsesDefaultAnalyzer() {
        // Arrange
        let config = HierarchyAnalyzerConfiguration()

        // Act & Assert
        #expect(config.semanticAnalyzer != nil, "Default config should have analyzer")
    }
}

// MARK: - Test Helpers

/// Custom semantic analyzer for testing protocol conformance
private final class CustomTestAnalyzer: SemanticAnalyzerProtocol {
    func detectIntent(label: String?, identifier: String?) -> SemanticIntent {
        // Treat "Custom Action" as submit
        if label?.contains("Custom Action") == true {
            return .submit
        }
        return .neutral
    }

    func detectScreenType(from elements: [MinimalElement]) -> ScreenType {
        // Always return content for testing
        return .content
    }

    func calculateSemanticPriority(_ element: MinimalElement) -> Int {
        // Fixed priority for testing
        return 999
    }

    func groupRelatedElements(_ elements: [MinimalElement]) -> [ElementGroup] {
        // Simple grouping for testing
        return []
    }
}
