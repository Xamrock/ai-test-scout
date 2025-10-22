import Foundation

/// Configuration options for HierarchyAnalyzer
public struct HierarchyAnalyzerConfiguration {
    /// Maximum depth to traverse in the element hierarchy (prevents infinite recursion)
    public var maxDepth: Int

    /// Maximum number of children to process per element (prevents excessive processing)
    public var maxChildrenPerElement: Int

    /// Whether to exclude keyboard elements from the hierarchy (recommended for AI crawlers)
    public var excludeKeyboard: Bool

    /// Whether to enrich elements with semantic metadata (intent, priority)
    public var useSemanticAnalysis: Bool

    /// Custom element categorizer for mapping XCUIElement types to simplified categories
    public var categorizer: ElementCategorizerProtocol

    /// Custom semantic analyzer for detecting intent and screen types (nil disables semantic analysis)
    public var semanticAnalyzer: SemanticAnalyzerProtocol?

    /// Optional delegate for customizing hierarchy capture behavior
    public weak var delegate: HierarchyAnalyzerDelegate?

    /// Initialize with default configuration
    public init(
        maxDepth: Int = 10,
        maxChildrenPerElement: Int = 50,
        excludeKeyboard: Bool = true,
        useSemanticAnalysis: Bool = true,
        categorizer: ElementCategorizerProtocol = DefaultElementCategorizer(),
        semanticAnalyzer: SemanticAnalyzerProtocol? = DefaultSemanticAnalyzer()
    ) {
        self.maxDepth = maxDepth
        self.maxChildrenPerElement = maxChildrenPerElement
        self.excludeKeyboard = excludeKeyboard
        self.useSemanticAnalysis = useSemanticAnalysis
        self.categorizer = categorizer
        self.semanticAnalyzer = semanticAnalyzer
    }
}
