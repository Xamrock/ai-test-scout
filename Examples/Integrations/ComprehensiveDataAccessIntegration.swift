import XCTest
import AITestScout

/// Example showing how to access the FULL UI hierarchy without affecting AI token usage
///
/// The `willCompressHierarchy` hook provides access to ALL captured elements (200+)
/// BEFORE compression to 50 elements for the AI. This enables comprehensive tools
/// to analyze the complete hierarchy without impacting AI performance.
///
/// **Key Benefit:** Two separate data streams:
/// 1. Comprehensive (200+ elements) → Your tools
/// 2. Compressed (50 elements) → AI decisions
@available(iOS 26.0, *)
@MainActor
final class ComprehensiveDataAccessIntegration: XCTestCase {

    var app: XCUIApplication!
    var analyzer: HierarchyAnalyzer!
    var crawler: AICrawler!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Set up analyzer with comprehensive access delegate
        let delegate = ComprehensiveAccessDelegate()
        var config = HierarchyAnalyzerConfiguration()
        config.delegate = delegate
        analyzer = HierarchyAnalyzer(configuration: config)

        // Initialize AI crawler
        crawler = try xcAwait { try await AICrawler() }
    }

    /// Example 1: Run comprehensive accessibility audit on ALL elements
    func testComprehensiveAccessibilityAudit() throws {
        app.launch()

        let maxSteps = 5

        for stepCount in 1...maxSteps {
            print("\n━━━ Step \(stepCount)/\(maxSteps) ━━━")

            // 1. Capture screen
            // The delegate's willCompressHierarchy hook will:
            // - Receive ALL elements (200+) for comprehensive analysis
            // - AI still only receives top 50 (no token impact)
            let hierarchy = analyzer.capture(from: app)

            print("📊 AI receives \(hierarchy.elements.count) elements")

            // 2. Get AI decision (based on compressed 50 elements)
            let decision = try awaitDecision(hierarchy: hierarchy)

            if decision.action == "done" {
                print("✅ Exploration complete")
                break
            }

            // 3. Execute action
            let succeeded = try executeAction(decision)
            if succeeded {
                sleep(1)
            }
        }

        print("\n✅ Comprehensive audit completed!")
    }

    /// Example 2: Combine comprehensive analysis with AI exploration
    func testComprehensiveWithExploration() throws {
        app.launch()

        let delegate = ComprehensiveAccessDelegate()
        var config = HierarchyAnalyzerConfiguration()
        config.delegate = delegate
        let customAnalyzer = HierarchyAnalyzer(configuration: config)

        for stepCount in 1...10 {
            print("\n📍 Step \(stepCount)/10")

            // Capture with comprehensive delegate
            let hierarchy = customAnalyzer.capture(from: app)

            // Delegate already ran comprehensive scans on ALL elements
            // Now AI makes decision based on compressed data (50 elements)
            let decision = try awaitDecision(hierarchy: hierarchy)

            if decision.action == "done" { break }

            try executeAction(decision)
            sleep(1)
        }

        // Print comprehensive stats from delegate
        delegate.printReport()
    }

    // MARK: - Helper Methods

    private func awaitDecision(hierarchy: CompressedHierarchy) throws -> ExplorationDecision {
        return try xcAwait {
            try await crawler.decideNextActionWithChoices(
                hierarchy: hierarchy,
                goal: "Explore and verify accessibility"
            )
        }
    }

    private func executeAction(_ decision: ExplorationDecision) throws -> Bool {
        switch decision.action {
        case "tap":
            guard let target = decision.targetElement else { return false }
            let element = app.descendants(matching: .any).matching(identifier: target).firstMatch
            guard element.exists else { return false }
            element.tap()
            return true

        case "type":
            guard let target = decision.targetElement,
                  let text = decision.textToType else { return false }
            let element = app.descendants(matching: .any).matching(identifier: target).firstMatch
            guard element.exists else { return false }
            element.tap()
            element.typeText(text)
            KeyboardHelper.dismissKeyboard(in: app)
            return true

        case "swipe":
            app.swipeUp()
            return true

        case "done":
            return true

        default:
            return false
        }
    }
}

// MARK: - Comprehensive Access Delegate

/// Delegate that demonstrates accessing ALL elements without affecting AI tokens
@available(iOS 26.0, *)
@MainActor
class ComprehensiveAccessDelegate: HierarchyAnalyzerDelegate {

    private var totalElementsSeen = 0
    private var accessibilityIssues: [String] = []
    private var screenAnalytics: [String: Int] = [:]

    /// 🔥 NEW HOOK: Access ALL elements BEFORE compression
    func willCompressHierarchy(app: XCUIApplication, allElements: [MinimalElement]) {
        print("📊 Comprehensive Analysis Hook Triggered")
        print("   Total elements: \(allElements.count)")

        totalElementsSeen += allElements.count

        // 1. Run comprehensive accessibility scan on ALL elements
        runFullAccessibilityScan(allElements)

        // 2. Analyze visual hierarchy structure
        analyzeVisualStructure(allElements)

        // 3. Custom XCUIApplication queries (if needed)
        runCustomQueries(app)

        // 4. Track analytics on complete hierarchy
        trackHierarchyAnalytics(allElements)

        // Note: AI will only receive top 50 elements via didCompleteCapture()
    }

    /// Called AFTER compression - AI receives this data (50 elements)
    func didCompleteCapture(_ hierarchy: CompressedHierarchy) {
        print("🤖 AI receives compressed data: \(hierarchy.elements.count) elements")
        print("   (Original: \(totalElementsSeen) elements in full scan)")
    }

    // MARK: - Comprehensive Analysis Methods

    private func runFullAccessibilityScan(_ allElements: [MinimalElement]) {
        var issues: [String] = []

        for element in allElements {
            // Check ALL elements, not just top 50
            if element.interactive && element.id == nil {
                issues.append("❌ Interactive element missing accessibility ID: \(element.label ?? "unknown")")
            }

            if element.interactive && element.label == nil {
                issues.append("❌ Interactive element missing label: \(element.id ?? "unknown")")
            }

            // Check for problematic label patterns
            if let label = element.label, label.lowercased().contains("click here") {
                issues.append("⚠️  Non-descriptive label: '\(label)'")
            }
        }

        accessibilityIssues.append(contentsOf: issues)

        if !issues.isEmpty {
            print("   🔍 Accessibility: Found \(issues.count) issues in full hierarchy")
            for issue in issues.prefix(3) {
                print("      \(issue)")
            }
            if issues.count > 3 {
                print("      ... and \(issues.count - 3) more")
            }
        } else {
            print("   ✅ Accessibility: No issues found in full hierarchy")
        }
    }

    private func analyzeVisualStructure(_ allElements: [MinimalElement]) {
        let buttons = allElements.filter { $0.type == .button }
        let inputs = allElements.filter { $0.type == .input }
        let images = allElements.filter { $0.type == .image }
        let text = allElements.filter { $0.type == .text }

        print("   📈 Visual Hierarchy Analysis:")
        print("      Buttons: \(buttons.count)")
        print("      Input Fields: \(inputs.count)")
        print("      Images: \(images.count)")
        print("      Text Elements: \(text.count)")

        // Check for common patterns
        if inputs.count > 3 {
            print("      💡 Detected form with \(inputs.count) fields")
        }

        if buttons.count > 10 {
            print("      💡 Detected button-heavy UI (navigation or toolbar)")
        }
    }

    private func runCustomQueries(_ app: XCUIApplication) {
        // Example: Find all elements with custom identifiers
        let customElements = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] 'custom'"))

        if customElements.count > 0 {
            print("   🔧 Custom Elements: Found \(customElements.count) custom-tagged elements")
        }

        // Example: Check for specific test identifiers
        let testElements = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] 'test'"))

        if testElements.count > 0 {
            print("   🧪 Test Elements: Found \(testElements.count) test-tagged elements")
        }
    }

    private func trackHierarchyAnalytics(_ allElements: [MinimalElement]) {
        // Track complete hierarchy stats
        screenAnalytics["totalElements"] = (screenAnalytics["totalElements"] ?? 0) + allElements.count

        let interactiveCount = allElements.filter { $0.interactive }.count
        screenAnalytics["interactiveElements"] = (screenAnalytics["interactiveElements"] ?? 0) + interactiveCount

        let identifiedCount = allElements.filter { $0.id != nil }.count
        screenAnalytics["identifiedElements"] = (screenAnalytics["identifiedElements"] ?? 0) + identifiedCount
    }

    // MARK: - Reporting

    func printReport() {
        print("\n" + String(repeating: "━", count: 60))
        print("📊 COMPREHENSIVE ANALYSIS REPORT")
        print(String(repeating: "━", count: 60))

        print("\n1️⃣  Element Statistics:")
        print("   Total elements analyzed: \(totalElementsSeen)")
        print("   Interactive elements: \(screenAnalytics["interactiveElements"] ?? 0)")
        print("   Elements with IDs: \(screenAnalytics["identifiedElements"] ?? 0)")

        print("\n2️⃣  Accessibility Issues:")
        if accessibilityIssues.isEmpty {
            print("   ✅ No issues found!")
        } else {
            print("   ⚠️  Found \(accessibilityIssues.count) issues:")
            for issue in accessibilityIssues.prefix(5) {
                print("      \(issue)")
            }
            if accessibilityIssues.count > 5 {
                print("      ... and \(accessibilityIssues.count - 5) more")
            }
        }

        print("\n3️⃣  Coverage:")
        let coverage = screenAnalytics["identifiedElements"] ?? 0
        let total = totalElementsSeen
        let percentage = total > 0 ? Double(coverage) / Double(total) * 100 : 0
        print("   Accessibility ID coverage: \(String(format: "%.1f", percentage))%")

        print("\n" + String(repeating: "━", count: 60))
    }
}

// MARK: - Usage Documentation

/*
 ## How to Use This Integration

 ### 1. Set Up Delegate
 ```swift
 let delegate = ComprehensiveAccessDelegate()
 var config = HierarchyAnalyzerConfiguration()
 config.delegate = delegate
 let analyzer = HierarchyAnalyzer(configuration: config)
 ```

 ### 2. Capture Triggers Hook Automatically
 ```swift
 let hierarchy = analyzer.capture(from: app)
 // Hook runs automatically:
 // - willCompressHierarchy(app, allElements: [200+ elements])
 // - Your comprehensive tools run here
 // - AI receives compressed 50 elements
 ```

 ### 3. Two Data Streams
 - **Comprehensive Stream** (willCompressHierarchy):
   - ALL elements (200+)
   - Full XCUIApplication access
   - For your tools
   - NOT sent to AI

 - **Compressed Stream** (didCompleteCapture):
   - Top 50 elements
   - Optimized for AI
   - Sent to AI for decisions

 ### 4. No Token Impact
 The comprehensive data is captured but NOT sent to AI, so:
 - ✅ Your tools see everything
 - ✅ AI gets optimized data
 - ✅ No increase in token usage
 - ✅ No degradation in AI quality

 ## Perfect For:
 - 🔍 Accessibility scanners needing 100% coverage
 - 📊 Analytics tools tracking all UI elements
 - 🎨 Visual regression tools analyzing layouts
 - 🔬 Research tools studying UI patterns
 - 📈 Performance monitors checking interactions
 - 🧪 Custom test validations on full hierarchy

 ## Key Methods:
 - `willCompressHierarchy()` - Access ALL elements + XCUIApplication
 - `didCompleteCapture()` - See what AI receives (50 elements)
 - `runFullAccessibilityScan()` - Scan complete hierarchy
 - `analyzeVisualStructure()` - Analyze full visual layout
 - `runCustomQueries()` - Run XCUIApplication queries
 - `trackHierarchyAnalytics()` - Track complete statistics
 */
