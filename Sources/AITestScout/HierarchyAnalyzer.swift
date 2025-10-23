import Foundation
import XCTest

/// CGRect extension for validation
private extension CGRect {
    var isFinite: Bool {
        return origin.x.isFinite && origin.y.isFinite &&
               size.width.isFinite && size.height.isFinite
    }
}

/// Element priority levels for intelligent element selection
private enum ElementPriority: Int, Comparable {
    case critical = 100  // Interactive + ID + Label
    case high = 75       // Interactive + (ID or Label)
    case medium = 50     // Interactive only, or Non-interactive + ID
    case low = 25        // Non-interactive + Label only

    static func < (lhs: ElementPriority, rhs: ElementPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Container for elements with priority for sorting
private struct PrioritizedElement: Comparable {
    let element: MinimalElement
    let priority: ElementPriority
    let semanticPriority: Int  // Semantic priority from SemanticAnalyzer (0-200+)

    static func < (lhs: PrioritizedElement, rhs: PrioritizedElement) -> Bool {
        // First compare by semantic priority (if available)
        if lhs.semanticPriority != rhs.semanticPriority {
            return lhs.semanticPriority < rhs.semanticPriority
        }
        // Fall back to structural priority
        return lhs.priority < rhs.priority
    }
}

/// Analyzes XCUITest element hierarchies and produces compressed, AI-friendly output
@MainActor
public class HierarchyAnalyzer {

    /// Maximum depth to traverse in the element hierarchy (prevents infinite recursion)
    private let maxDepth: Int

    /// Maximum number of children to process per element (prevents excessive processing)
    private let maxChildrenPerElement: Int

    /// Whether to exclude keyboard elements from the hierarchy (recommended for AI crawlers)
    private let excludeKeyboard: Bool

    /// Semantic analyzer for understanding element intent and priority
    private let semanticAnalyzer: SemanticAnalyzerProtocol?

    /// Whether to enrich elements with semantic metadata (intent, priority)
    private let useSemanticAnalysis: Bool

    /// Element categorizer for mapping XCUIElement types to simplified categories
    private let categorizer: ElementCategorizerProtocol

    /// Optional delegate for customizing hierarchy capture behavior
    nonisolated(unsafe) private weak var delegate: HierarchyAnalyzerDelegate?

    /// Element contexts captured during hierarchy analysis (for LLM export)
    /// Keyed by element identifier: "type|id|label"
    nonisolated(unsafe) private var elementContextMap: [String: ElementContext] = [:]

    /// Public accessor for captured element contexts
    public var capturedElementContexts: [String: ElementContext] {
        return elementContextMap
    }

    /// Initialize with configuration object (recommended)
    /// - Parameter configuration: Configuration options for the analyzer
    nonisolated public init(configuration: HierarchyAnalyzerConfiguration) {
        self.maxDepth = configuration.maxDepth
        self.maxChildrenPerElement = configuration.maxChildrenPerElement
        self.excludeKeyboard = configuration.excludeKeyboard
        self.useSemanticAnalysis = configuration.useSemanticAnalysis
        self.categorizer = configuration.categorizer
        self.semanticAnalyzer = configuration.semanticAnalyzer
        self.delegate = configuration.delegate
    }

    /// Initialize with individual parameters (backward compatibility)
    /// - Parameters:
    ///   - maxDepth: Maximum hierarchy depth (default: 10)
    ///   - maxChildrenPerElement: Max children to process (default: 50)
    ///   - excludeKeyboard: Whether to exclude keyboard elements (default: true)
    ///   - useSemanticAnalysis: Whether to add semantic metadata (default: true)
    nonisolated public convenience init(
        maxDepth: Int = 10,
        maxChildrenPerElement: Int = 50,
        excludeKeyboard: Bool = true,
        useSemanticAnalysis: Bool = true
    ) {
        var config = HierarchyAnalyzerConfiguration()
        config.maxDepth = maxDepth
        config.maxChildrenPerElement = maxChildrenPerElement
        config.excludeKeyboard = excludeKeyboard
        config.useSemanticAnalysis = useSemanticAnalysis
        self.init(configuration: config)
    }

    /// Captures the view hierarchy from an XCUIApplication
    /// - Parameter app: The XCUIApplication to analyze
    /// - Returns: A CompressedHierarchy ready for AI consumption
    @MainActor
    public func capture(from app: XCUIApplication) -> CompressedHierarchy {
        // Notify delegate that capture is beginning
        delegate?.willBeginCapture()

        // Capture screenshot (may log XCTest warnings on timing/frame issues, but won't crash)
        let screenshotData: Data
        if app.frame.isEmpty {
            // App has empty frame - skip screenshot to avoid XCTest error
            screenshotData = Data()
        } else {
            let screenshot = app.screenshot()
            screenshotData = screenshot.pngRepresentation
        }

        // Capture ALL elements before compression (for comprehensive tools)
        let allElements = captureAllElementsFromApp(app)

        // Notify delegate with full data BEFORE compression
        // This allows comprehensive tools to access ALL elements without affecting AI token usage
        delegate?.willCompressHierarchy(app: app, allElements: allElements)

        // Apply compression/prioritization (reduce to top 50 for AI)
        let compressedElements = compressElements(allElements)

        // Detect screen type using semantic analysis
        let screenType = useSemanticAnalysis ? detectScreenType(from: compressedElements) : nil

        let hierarchy = CompressedHierarchy(
            elements: compressedElements,
            screenshot: screenshotData,
            screenType: screenType
        )

        // Notify delegate that capture completed successfully (with compressed data)
        delegate?.didCompleteCapture(hierarchy)

        return hierarchy
    }

    /// Detects the type of screen from captured elements
    private func detectScreenType(from elements: [MinimalElement]) -> ScreenType? {
        guard let analyzer = semanticAnalyzer else { return nil }

        let detectedType = analyzer.detectScreenType(from: elements)

        // Don't return generic "content" type as it's not informative
        return detectedType == .content ? nil : detectedType
    }

    /// Generates a unique key for an element to track duplicates
    /// - Parameter element: The MinimalElement to generate a key for
    /// - Returns: A unique string key combining type, id, and label
    private func elementKey(for element: MinimalElement) -> String {
        return "\(element.type.rawValue)|\(element.id ?? "")|\(element.label ?? "")"
    }

    /// Gets the semantic priority for an element (delegate takes precedence)
    /// - Parameter element: The MinimalElement to get priority for
    /// - Returns: The semantic priority value (from delegate or element's own priority)
    private func getSemanticPriority(for element: MinimalElement) -> Int {
        if let delegatePriority = delegate?.priorityForElement(element) {
            return delegatePriority
        }
        return element.priority ?? 0
    }

    /// Captures ALL elements from the XCUIApplication (no compression)
    /// - Parameter app: The XCUIApplication to analyze
    /// - Returns: Array of ALL captured MinimalElement representations
    @MainActor
    private func captureAllElementsFromApp(_ app: XCUIApplication) -> [MinimalElement] {
        var prioritizedElements: [PrioritizedElement] = []
        var seenElements = Set<String>()  // O(1) duplicate tracking

        // Detect if keyboard is present
        let keyboardPresent = excludeKeyboard && app.keyboards.firstMatch.exists

        // Define interactive element types to query (reduces queries by ~80%)
        let interactiveTypes: [XCUIElement.ElementType] = [
            .button, .textField, .secureTextField, .searchField,
            .switch, .toggle, .link, .tab, .tabBar,
            .slider, .stepper, .picker, .pickerWheel,
            .segmentedControl, .pageIndicator
        ]

        // Phase 1: Collect interactive elements by type (targeted queries)
        for elementType in interactiveTypes {
            let elements = app.descendants(matching: elementType)
            let count = min(elements.count, 20)  // Max 20 per type to limit queries

            for i in 0..<count {
                let element = elements.element(boundBy: i)

                // Skip if element doesn't exist
                guard element.exists else { continue }

                // Skip system UI elements
                guard !categorizer.shouldSkip(elementType) else { continue }

                // Skip keyboard elements
                if excludeKeyboard && keyboardPresent && isKeyboardElement(element) {
                    continue
                }

                // Create minimal element and calculate priority
                let minimalElement = createMinimalElement(from: element)

                // Only include if it has meaningful content
                guard shouldInclude(minimalElement) else { continue }

                // Track element to prevent duplicates in Phase 2
                let key = elementKey(for: minimalElement)
                seenElements.insert(key)

                // Capture detailed context for LLM export
                _ = captureElementContext(from: element, minimalElement: minimalElement, index: i)

                let priority = calculatePriority(for: minimalElement)
                let semanticPriority = getSemanticPriority(for: minimalElement)

                prioritizedElements.append(PrioritizedElement(
                    element: minimalElement,
                    priority: priority,
                    semanticPriority: semanticPriority
                ))
            }
        }

        // Phase 2: Backfill with important non-interactive elements
        // These provide context (e.g., screen titles, important labels with IDs)
        let identifiedElements = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier != ''"))
        let idCount = identifiedElements.count

        for i in 0..<idCount {
            let element = identifiedElements.element(boundBy: i)

            guard element.exists else { continue }
            guard !categorizer.shouldSkip(element.elementType) else { continue }

            if excludeKeyboard && keyboardPresent && isKeyboardElement(element) {
                continue
            }

            let minimalElement = createMinimalElement(from: element)

            guard shouldInclude(minimalElement) else { continue }

            // Check if element already exists (O(1) lookup)
            let key = elementKey(for: minimalElement)
            guard !seenElements.contains(key) else { continue }
            seenElements.insert(key)

            // Capture detailed context for LLM export
            _ = captureElementContext(from: element, minimalElement: minimalElement, index: i)

            let priority = calculatePriority(for: minimalElement)
            let semanticPriority = getSemanticPriority(for: minimalElement)

            prioritizedElements.append(PrioritizedElement(
                element: minimalElement,
                priority: priority,
                semanticPriority: semanticPriority
            ))
        }

        // Return all elements sorted by priority (highest first)
        let allElements = prioritizedElements
            .sorted(by: >) // Highest priority first
            .map { $0.element }

        return allElements
    }

    /// Compresses elements to top 50 for AI consumption
    /// - Parameter allElements: All captured elements
    /// - Returns: Top 50 elements by priority
    private func compressElements(_ allElements: [MinimalElement]) -> [MinimalElement] {
        let targetCount = 50  // Optimized for AI token efficiency
        return Array(allElements.prefix(targetCount))
    }

    /// Checks if an element is part of the keyboard hierarchy
    /// - Parameter element: The XCUIElement to check
    /// - Returns: True if the element is part of the keyboard
    @MainActor
    private func isKeyboardElement(_ element: XCUIElement) -> Bool {
        // Check if element identifier contains keyboard-related strings
        let identifier = element.identifier.lowercased()
        let keyboardIdentifiers = ["keyboard", "autocorrection", "prediction", "emoji"]

        for keyboardId in keyboardIdentifiers {
            if identifier.contains(keyboardId) {
                return true
            }
        }

        // Check if element label suggests it's a keyboard key
        let label = element.label.lowercased()
        if label.count == 1 {
            // Single character labels are likely keyboard keys
            return true
        }

        // Check for common keyboard button labels
        let keyboardLabels = ["return", "space", "shift", "delete", "next keyboard",
                             "dictation", "emoji", "done", "go", "search", "send"]
        for keyboardLabel in keyboardLabels {
            if label.contains(keyboardLabel) || label == keyboardLabel {
                return true
            }
        }

        return false
    }

    /// Creates a MinimalElement from an XCUIElement
    /// - Parameter element: The XCUIElement to convert
    /// - Returns: A MinimalElement representation
    @MainActor
    private func createMinimalElement(from element: XCUIElement) -> MinimalElement {
        let category = categorizer.categorize(element.elementType)

        // Capture current value for interactive elements (helps AI understand state)
        var value: String? = nil
        if category.interactive {
            // Get value from element.value (for inputs, toggles, sliders, etc.)
            if let elementValue = element.value as? String, !elementValue.isEmpty {
                value = elementValue
            } else if let elementValue = element.value as? NSNumber {
                // For toggles (0/1) and sliders (numeric values)
                value = elementValue.stringValue
            }
        }

        // Convert string type to ElementType enum
        let elementType = ElementType(rawValue: category.type) ?? .container

        // Add semantic metadata if enabled
        var intent: SemanticIntent? = nil
        var priority: Int? = nil

        if useSemanticAnalysis, let analyzer = semanticAnalyzer {
            let id = element.identifier.isEmpty ? nil : element.identifier
            let label = element.label.isEmpty ? nil : element.label

            let detectedIntent = analyzer.detectIntent(label: label, identifier: id)
            intent = detectedIntent == .neutral ? nil : detectedIntent

            // Create temporary minimal element for priority calculation
            let tempElement = MinimalElement(
                type: elementType,
                id: id,
                label: label,
                interactive: category.interactive,
                value: value,
                children: []
            )
            priority = analyzer.calculateSemanticPriority(tempElement)
        }

        return MinimalElement(
            type: elementType,
            id: element.identifier.isEmpty ? nil : element.identifier,
            label: element.label.isEmpty ? nil : element.label,
            interactive: category.interactive,
            value: value,
            intent: intent,
            priority: priority,
            children: []
        )
    }

    /// Calculates priority for an element based on its properties
    /// - Parameter element: The MinimalElement to evaluate
    /// - Returns: The calculated ElementPriority
    private func calculatePriority(for element: MinimalElement) -> ElementPriority {
        let hasId = element.id != nil && !element.id!.isEmpty
        let hasLabel = element.label != nil && !element.label!.isEmpty
        let isInteractive = element.interactive

        // Critical: Interactive elements with both ID and label (e.g., loginButton with "Sign In")
        if isInteractive && hasId && hasLabel {
            return .critical
        }

        // High: Interactive elements with either ID or label
        if isInteractive && (hasId || hasLabel) {
            return .high
        }

        // Medium: Interactive without identification, or important non-interactive (has ID)
        if isInteractive || hasId {
            return .medium
        }

        // Low: Non-interactive with only label
        if hasLabel {
            return .low
        }

        return .low
    }

    /// Determines if an element should be included in the final output
    /// - Parameter element: The MinimalElement to evaluate
    /// - Returns: True if the element should be included
    private func shouldInclude(_ element: MinimalElement) -> Bool {
        // Check default inclusion logic first
        var shouldIncludeByDefault = false

        // Always include interactive elements
        if element.interactive { shouldIncludeByDefault = true }

        // Include text elements with actual content
        else if element.type == .text && element.label != nil { shouldIncludeByDefault = true }

        // Include images (they provide visual context)
        else if element.type == .image { shouldIncludeByDefault = true }

        // Include any element with an identifier (developer marked as important)
        else if element.id != nil { shouldIncludeByDefault = true }

        // Include any element with a label (has user-facing content)
        else if element.label != nil { shouldIncludeByDefault = true }

        // If default logic says to skip, don't include
        if !shouldIncludeByDefault {
            return false
        }

        // Consult delegate for final decision (delegate can veto inclusion)
        if let delegate = delegate {
            return delegate.shouldInclude(element)
        }

        return true
    }

    /// Captures detailed element context for LLM test generation
    /// - Parameters:
    ///   - element: The XCUIElement to capture context from
    ///   - minimalElement: The corresponding MinimalElement
    ///   - index: Element index among siblings of same type
    /// - Returns: ElementContext with queries, frame, state, etc.
    @MainActor
    private func captureElementContext(
        from element: XCUIElement,
        minimalElement: MinimalElement,
        index: Int
    ) -> ElementContext {
        // Build query strategies
        let queries = QueryBuilder.buildQueries(
            elementType: element.elementType,
            id: minimalElement.id,
            label: minimalElement.label,
            index: index
        )

        // Capture accessibility traits
        let traits = captureAccessibilityTraits(from: element)

        // Safe hittability check (skip for elements with empty/invalid frames)
        let isHittable: Bool
        if element.frame.isEmpty || !element.frame.isFinite {
            // Element has invalid frame - assume not hittable to avoid XCTest assertion
            isHittable = false
        } else {
            // Safe to check hittability
            isHittable = element.isHittable
        }

        // Create context
        let context = ElementContext(
            xcuiElementType: String(describing: element.elementType),
            frame: element.frame,
            isEnabled: element.isEnabled,
            isVisible: element.exists && isHittable,
            isHittable: isHittable,
            hasFocus: false, // XCUIElement doesn't expose focus state directly
            queries: queries,
            accessibilityTraits: traits,
            accessibilityHint: nil // XCUIElement doesn't expose hint directly
        )

        // Store in map
        let key = elementKey(for: minimalElement)
        elementContextMap[key] = context

        // Notify delegate
        delegate?.didCaptureElementContext(minimalElement, context: context)

        return context
    }

    /// Captures accessibility traits from an element
    /// - Parameter element: The XCUIElement
    /// - Returns: Array of trait strings
    @MainActor
    private func captureAccessibilityTraits(from element: XCUIElement) -> [String]? {
        // XCUIElement doesn't expose traits directly, so we infer from element type
        // This is a simplified implementation
        var traits: [String] = []

        switch element.elementType {
        case .button:
            traits.append("button")
        case .textField, .secureTextField, .searchField:
            traits.append("textField")
        case .staticText:
            traits.append("staticText")
        case .image:
            traits.append("image")
        case .link:
            traits.append("link")
        default:
            break
        }

        return traits.isEmpty ? nil : traits
    }

    /// Method to clear captured contexts (useful for memory management in long sessions)
    public func clearCapturedContexts() {
        elementContextMap.removeAll()
    }
}
