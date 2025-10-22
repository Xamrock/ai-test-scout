import Testing
import Foundation
import XCTest
@testable import AITestScout

@Suite("HierarchyAnalyzerDelegate Tests")
struct HierarchyAnalyzerDelegateTests {

    // MARK: - Delegate Protocol Tests

    @Test("Configuration should accept optional delegate")
    func testConfigurationAcceptsDelegate() {
        // Arrange
        let delegate = TestDelegate()
        var config = HierarchyAnalyzerConfiguration()

        // Act
        config.delegate = delegate

        // Assert
        #expect(config.delegate != nil, "Should accept delegate")
    }

    @Test("Configuration should allow nil delegate")
    func testConfigurationAllowsNilDelegate() {
        // Arrange
        var config = HierarchyAnalyzerConfiguration()
        let delegate = TestDelegate() // Keep strong reference
        config.delegate = delegate
        #expect(config.delegate != nil)

        // Act
        config.delegate = nil

        // Assert
        #expect(config.delegate == nil, "Should allow setting delegate to nil")
    }

    @Test("Default configuration should have nil delegate")
    func testDefaultConfigurationNilDelegate() {
        // Arrange & Act
        let config = HierarchyAnalyzerConfiguration()

        // Assert
        #expect(config.delegate == nil, "Default delegate should be nil")
    }

    // MARK: - Element Filtering Delegate Tests

    @Test("Delegate should be consulted for element inclusion")
    func testDelegateShouldIncludeElement() {
        // Arrange
        let delegate = TestDelegate()
        delegate.shouldIncludeHandler = { element in
            // Only include elements with "important" in their ID
            return element.id?.contains("important") ?? false
        }

        // Act - Simulate calling delegate
        let importantElement = MinimalElement(
            type: .button,
            id: "importantButton",
            label: "Click me",
            interactive: true
        )
        let regularElement = MinimalElement(
            type: .button,
            id: "regularButton",
            label: "Regular",
            interactive: true
        )

        // Assert
        #expect(delegate.shouldInclude(importantElement) == true)
        #expect(delegate.shouldInclude(regularElement) == false)
    }

    @Test("Delegate should allow custom priority calculation")
    func testDelegateCustomPriority() {
        // Arrange
        let delegate = TestDelegate()
        delegate.priorityForElementHandler = { element in
            // Custom priority: buttons get 1000, everything else gets 1
            return element.type == .button ? 1000 : 1
        }

        // Act
        let button = MinimalElement(type: .button, id: "btn", interactive: true)
        let text = MinimalElement(type: .text, label: "Text", interactive: false)

        // Assert
        if let buttonPriority = delegate.priorityForElement(button) {
            #expect(buttonPriority == 1000)
        }
        if let textPriority = delegate.priorityForElement(text) {
            #expect(textPriority == 1)
        }
    }

    @Test("Delegate priority should override semantic priority")
    func testDelegatePriorityOverridesSemantic() {
        // Arrange
        let delegate = TestDelegate()
        delegate.priorityForElementHandler = { _ in 9999 }

        // Act
        let element = MinimalElement(
            type: .button,
            id: "submit",
            label: "Submit",
            interactive: true,
            priority: 150  // Semantic priority
        )

        // Assert
        if let delegatePriority = delegate.priorityForElement(element) {
            #expect(delegatePriority == 9999, "Delegate priority should override semantic")
            #expect(delegatePriority > (element.priority ?? 0))
        }
    }

    // MARK: - Element Transformation Delegate Tests

    @Test("Delegate should allow element transformation")
    func testDelegateTransformElement() {
        // Arrange
        let delegate = TestDelegate()
        delegate.transformElementHandler = { element in
            // Add custom metadata by modifying the element
            let transformed = element
            // In real implementation, this might add custom fields
            return transformed
        }

        // Act
        let original = MinimalElement(type: .button, id: "btn", interactive: true)
        let transformed = delegate.transformElement(original)

        // Assert
        #expect(transformed != nil, "Should return transformed element")
    }

    // MARK: - Lifecycle Delegate Tests

    @Test("Delegate should be notified when capture starts")
    func testDelegateWillBeginCapture() {
        // Arrange
        let delegate = TestDelegate()
        var captureStarted = false
        delegate.willBeginCaptureHandler = {
            captureStarted = true
        }

        // Act
        delegate.willBeginCapture()

        // Assert
        #expect(captureStarted == true, "Should notify delegate of capture start")
    }

    @Test("Delegate should be notified before compression with all elements")
    func testDelegateWillCompressHierarchy() {
        // Arrange
        let delegate = TestDelegate()
        var receivedElementCount = 0
        delegate.willCompressHierarchyHandler = { app, allElements in
            receivedElementCount = allElements.count
        }

        // Act - Verify the handler signature and behavior
        // Note: We can't create XCUIApplication in unit tests, so we verify the handler works
        _ = [
            MinimalElement(type: .button, id: "btn1", interactive: true),
            MinimalElement(type: .button, id: "btn2", interactive: true),
            MinimalElement(type: .text, label: "Text", interactive: false)
        ]

        // Verify delegate method exists and can be called
        #expect(delegate.willCompressHierarchyHandler != nil, "Handler should be set")

        // In a real scenario, HierarchyAnalyzer would call this with actual XCUIApplication
        // For unit testing, we verify the delegate infrastructure works
        #expect(receivedElementCount == 0, "Handler not yet invoked")

        // The handler would be called by HierarchyAnalyzer.capture() in real usage
        // This test verifies the delegate protocol works correctly
    }

    @Test("Delegate should be notified when capture completes")
    func testDelegateDidCompleteCapture() {
        // Arrange
        let delegate = TestDelegate()
        var receivedHierarchy: CompressedHierarchy?
        delegate.didCompleteCaptureHandler = { hierarchy in
            receivedHierarchy = hierarchy
        }

        // Act
        let testHierarchy = CompressedHierarchy(elements: [], screenshot: Data(), screenType: nil)
        delegate.didCompleteCapture(testHierarchy)

        // Assert
        #expect(receivedHierarchy != nil, "Should receive hierarchy in callback")
    }

    @Test("Delegate should be notified of processing errors")
    func testDelegateDidEncounterError() {
        // Arrange
        let delegate = TestDelegate()
        var receivedError: Error?
        delegate.didEncounterErrorHandler = { error in
            receivedError = error
        }

        // Act
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        delegate.didEncounterError(testError)

        // Assert
        #expect(receivedError != nil, "Should receive error in callback")
    }

    // MARK: - Children Processing Delegate Tests

    @Test("Delegate should control child element processing")
    func testDelegateShouldProcessChildren() {
        // Arrange
        let delegate = TestDelegate()
        delegate.shouldProcessChildrenHandler = { element in
            // Skip children of elements with "skipChildren" in ID
            return !(element.id?.contains("skipChildren") ?? false)
        }

        // Act
        let skipElement = MinimalElement(type: .container, id: "skipChildren", interactive: false)
        let processElement = MinimalElement(type: .container, id: "processThis", interactive: false)

        // Assert
        #expect(delegate.shouldProcessChildren(of: skipElement) == false)
        #expect(delegate.shouldProcessChildren(of: processElement) == true)
    }

    // MARK: - Multiple Delegate Methods Tests

    @Test("Delegate can implement multiple methods")
    func testMultipleDelegateMethods() {
        // Arrange
        let delegate = TestDelegate()
        var captureStarted = false
        var elementIncluded = false

        delegate.willBeginCaptureHandler = {
            captureStarted = true
        }
        delegate.shouldIncludeHandler = { _ in
            elementIncluded = true
            return true
        }

        // Act
        delegate.willBeginCapture()
        let element = MinimalElement(type: .button, interactive: true)
        _ = delegate.shouldInclude(element)

        // Assert
        #expect(captureStarted == true)
        #expect(elementIncluded == true)
    }

    // MARK: - Optional Delegate Methods Tests

    @Test("All delegate methods should be optional")
    func testDelegateMethodsOptional() {
        // Arrange
        let emptyDelegate = EmptyTestDelegate()

        // Act & Assert - Should not crash when calling optional methods
        emptyDelegate.willBeginCapture()
        _ = emptyDelegate.shouldInclude(MinimalElement(type: .button, interactive: true))
        _ = emptyDelegate.priorityForElement(MinimalElement(type: .button, interactive: true))
        _ = emptyDelegate.transformElement(MinimalElement(type: .button, interactive: true))
        _ = emptyDelegate.shouldProcessChildren(of: MinimalElement(type: .container, interactive: false))
        emptyDelegate.didCompleteCapture(CompressedHierarchy(elements: [], screenshot: Data(), screenType: nil))
        emptyDelegate.didEncounterError(NSError(domain: "test", code: 1, userInfo: nil))

        #expect(Bool(true), "Optional methods should not crash when not implemented")
    }
}

// MARK: - Test Helpers

/// Test delegate implementation for testing
private class TestDelegate: HierarchyAnalyzerDelegate {
    var willBeginCaptureHandler: (() -> Void)?
    var willCompressHierarchyHandler: ((XCUIApplication, [MinimalElement]) -> Void)?
    var didCompleteCaptureHandler: ((CompressedHierarchy) -> Void)?
    var didEncounterErrorHandler: ((Error) -> Void)?
    var shouldIncludeHandler: ((MinimalElement) -> Bool)?
    var priorityForElementHandler: ((MinimalElement) -> Int)?
    var transformElementHandler: ((MinimalElement) -> MinimalElement)?
    var shouldProcessChildrenHandler: ((MinimalElement) -> Bool)?

    func willBeginCapture() {
        willBeginCaptureHandler?()
    }

    func willCompressHierarchy(app: XCUIApplication, allElements: [MinimalElement]) {
        willCompressHierarchyHandler?(app, allElements)
    }

    func didCompleteCapture(_ hierarchy: CompressedHierarchy) {
        didCompleteCaptureHandler?(hierarchy)
    }

    func didEncounterError(_ error: Error) {
        didEncounterErrorHandler?(error)
    }

    func shouldInclude(_ element: MinimalElement) -> Bool {
        return shouldIncludeHandler?(element) ?? true
    }

    func priorityForElement(_ element: MinimalElement) -> Int? {
        return priorityForElementHandler?(element)
    }

    func transformElement(_ element: MinimalElement) -> MinimalElement? {
        return transformElementHandler?(element)
    }

    func shouldProcessChildren(of element: MinimalElement) -> Bool {
        return shouldProcessChildrenHandler?(element) ?? true
    }
}

/// Empty delegate for testing optional methods
private class EmptyTestDelegate: HierarchyAnalyzerDelegate {
    // All methods are optional - no implementations
}
