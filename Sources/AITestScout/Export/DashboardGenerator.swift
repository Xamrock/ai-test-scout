import Foundation

/// Generates an interactive HTML dashboard for exploration results
@available(macOS 26.0, iOS 26.0, *)
public class DashboardGenerator {

    public init() {}

    /// Generates a complete HTML dashboard
    /// - Parameters:
    ///   - result: The exploration result
    ///   - generatedTestCode: The generated Swift test code (optional)
    ///   - steps: Exploration steps for timeline (optional)
    /// - Returns: HTML string ready to write to file
    public func generate(
        result: ExplorationResult,
        generatedTestCode: String? = nil,
        steps: [ExplorationStep]? = nil
    ) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AITestScout Exploration Report</title>
            <style>
                \(cssStyles)
            </style>
        </head>
        <body>
            <div class="container">
                \(headerSection(result: result))
                \(metricsSection(result: result))
                \(quickActionsSection(result: result))
                \(timelineSection(steps: steps ?? []))
                \(generatedTestsSection(testCode: generatedTestCode))
                \(coverageSection(result: result))
                \(footerSection())
            </div>
            <script>
                \(javascript)
            </script>
        </body>
        </html>
        """
    }

    // MARK: - HTML Sections

    private func headerSection(result: ExplorationResult) -> String {
        let statusEmoji = result.hasCriticalFailures ? "⚠️" : "✅"
        let statusText = result.hasCriticalFailures ? "Issues Found" : "Success"
        let statusClass = result.hasCriticalFailures ? "status-warning" : "status-success"

        return """
        <header class="header">
            <div class="header-content">
                <h1>🤖 AITestScout Exploration Report</h1>
                <div class="status-badge \(statusClass)">
                    <span class="status-icon">\(statusEmoji)</span>
                    <span>\(statusText)</span>
                </div>
            </div>
            <div class="timestamp">Generated: \(formatDate(Date()))</div>
        </header>
        """
    }

    private func metricsSection(result: ExplorationResult) -> String {
        return """
        <section class="metrics">
            <div class="metric-card">
                <div class="metric-icon">📱</div>
                <div class="metric-value">\(result.screensDiscovered)</div>
                <div class="metric-label">Screens</div>
            </div>
            <div class="metric-card">
                <div class="metric-icon">🔄</div>
                <div class="metric-value">\(result.transitions)</div>
                <div class="metric-label">Transitions</div>
            </div>
            <div class="metric-card">
                <div class="metric-icon">⏱️</div>
                <div class="metric-value">\(formatDuration(result.duration))</div>
                <div class="metric-label">Duration</div>
            </div>
            <div class="metric-card">
                <div class="metric-icon">🎯</div>
                <div class="metric-value">\(result.successRatePercent)%</div>
                <div class="metric-label">Success Rate</div>
            </div>
            <div class="metric-card \(result.hasCriticalFailures ? "metric-warning" : "")">
                <div class="metric-icon">\(result.hasCriticalFailures ? "❌" : "✅")</div>
                <div class="metric-value">\(result.failedActions)</div>
                <div class="metric-label">Failures</div>
            </div>
        </section>
        """
    }

    private func quickActionsSection(result: ExplorationResult) -> String {
        var buttons = ""

        if result.generatedTestFile != nil {
            buttons += """
            <button class="btn btn-primary" onclick="copyAllTests()">
                📋 Copy All Tests
            </button>
            """
        }

        if let testFile = result.generatedTestFile {
            buttons += """
            <button class="btn btn-secondary" onclick="window.open('\(testFile.absoluteString)', '_blank')">
                📄 Open Test File
            </button>
            """
        }

        if let reportFile = result.generatedReportFile {
            buttons += """
            <button class="btn btn-secondary" onclick="window.open('\(reportFile.absoluteString)', '_blank')">
                📊 View Raw Report
            </button>
            """
        }

        guard !buttons.isEmpty else { return "" }

        return """
        <section class="quick-actions">
            <h2>Quick Actions</h2>
            <div class="button-group">
                \(buttons)
            </div>
        </section>
        """
    }

    private func timelineSection(steps: [ExplorationStep]) -> String {
        guard !steps.isEmpty else { return "" }

        let stepItems = steps.enumerated().map { index, step in
            let icon = step.wasSuccessful ? "✅" : "❌"
            let statusClass = step.wasSuccessful ? "step-success" : "step-failure"
            let targetText = step.targetElement.map { "`\($0)`" } ?? "N/A"
            let textTypedHTML = step.textTyped.map { """
                <div class="step-detail"><strong>Text:</strong> "\($0)"</div>
                """ } ?? ""

            return """
            <div class="timeline-item \(statusClass)">
                <div class="timeline-marker">\(icon)</div>
                <div class="timeline-content">
                    <div class="timeline-header">
                        <span class="timeline-number">Step \(index + 1)</span>
                        <span class="timeline-action">\(step.action.uppercased())</span>
                    </div>
                    <div class="step-detail"><strong>Target:</strong> \(targetText)</div>
                    \(textTypedHTML)
                    <div class="step-detail"><strong>Reasoning:</strong> \(escapeHtml(step.reasoning))</div>
                    <div class="step-detail"><strong>Confidence:</strong> \(step.confidence)%</div>
                </div>
            </div>
            """
        }.joined(separator: "\n")

        return """
        <section class="timeline-section">
            <h2>📍 Exploration Timeline</h2>
            <div class="timeline">
                \(stepItems)
            </div>
        </section>
        """
    }

    private func generatedTestsSection(testCode: String?) -> String {
        guard let code = testCode, !code.isEmpty else { return "" }

        let escapedCode = escapeHtml(code)

        return """
        <section class="tests-section">
            <h2>🧪 Generated Tests</h2>
            <div class="test-container">
                <div class="test-header">
                    <span class="test-title">GeneratedUITests.swift</span>
                    <button class="btn btn-small" onclick="copyCode('all-tests')">
                        📋 Copy
                    </button>
                </div>
                <pre id="all-tests" class="code-block"><code class="language-swift">\(escapedCode)</code></pre>
            </div>
        </section>
        """
    }

    private func coverageSection(result: ExplorationResult) -> String {
        var verificationHTML = ""
        if result.verificationsPerformed > 0 {
            verificationHTML = """
            <div class="coverage-item">
                <div class="coverage-label">🔍 Verification Pass Rate</div>
                <div class="coverage-value">\(result.verificationSuccessRate)%</div>
                <div class="coverage-subtext">\(result.verificationsPassed)/\(result.verificationsPerformed) passed</div>
            </div>
            """

            if result.retryAttempts > 0 {
                verificationHTML += """
                <div class="coverage-item">
                    <div class="coverage-label">🔄 Retry Attempts</div>
                    <div class="coverage-value">\(result.retryAttempts)</div>
                    <div class="coverage-subtext">Alternative actions tried</div>
                </div>
                """
            }
        }

        return """
        <section class="coverage-section">
            <h2>📊 Coverage & Stats</h2>
            <div class="coverage-grid">
                <div class="coverage-item">
                    <div class="coverage-label">🎯 Success Rate</div>
                    <div class="coverage-value">\(result.successRatePercent)%</div>
                    <div class="coverage-subtext">\(result.successfulActions)/\(result.totalActions) actions</div>
                </div>
                <div class="coverage-item">
                    <div class="coverage-label">📱 Screen Coverage</div>
                    <div class="coverage-value">\(result.screensDiscovered)</div>
                    <div class="coverage-subtext">Unique screens</div>
                </div>
                <div class="coverage-item">
                    <div class="coverage-label">🔄 Transitions</div>
                    <div class="coverage-value">\(result.transitions)</div>
                    <div class="coverage-subtext">Navigation paths</div>
                </div>
                \(verificationHTML)
            </div>
        </section>
        """
    }

    private func footerSection() -> String {
        return """
        <footer class="footer">
            <div class="footer-content">
                <div class="powered-by">
                    🚀 Powered by <strong>Xamrock AITestScout</strong>
                </div>
                <div class="footer-links">
                    <a href="https://xamrock.com" target="_blank">xamrock.com</a>
                    <span class="separator">•</span>
                    <a href="https://github.com/xamrock/ai-test-scout" target="_blank">GitHub</a>
                </div>
            </div>
        </footer>
        """
    }

    // MARK: - Styles

    private var cssStyles: String {
        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            line-height: 1.6;
            padding: 20px;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
        }

        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }

        .header h1 {
            font-size: 2rem;
            font-weight: 700;
        }

        .status-badge {
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .status-success {
            background: rgba(16, 185, 129, 0.2);
            border: 2px solid rgba(16, 185, 129, 0.5);
        }

        .status-warning {
            background: rgba(245, 158, 11, 0.2);
            border: 2px solid rgba(245, 158, 11, 0.5);
        }

        .timestamp {
            opacity: 0.9;
            font-size: 0.9rem;
        }

        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8fafc;
        }

        .metric-card {
            background: white;
            padding: 24px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            transition: transform 0.2s;
        }

        .metric-card:hover {
            transform: translateY(-4px);
        }

        .metric-warning {
            border: 2px solid #f59e0b;
        }

        .metric-icon {
            font-size: 2.5rem;
            margin-bottom: 8px;
        }

        .metric-value {
            font-size: 2rem;
            font-weight: 700;
            color: #667eea;
        }

        .metric-label {
            color: #64748b;
            font-size: 0.9rem;
            margin-top: 4px;
        }

        section {
            padding: 40px;
            border-top: 1px solid #e2e8f0;
        }

        h2 {
            font-size: 1.5rem;
            margin-bottom: 24px;
            color: #1e293b;
        }

        .quick-actions {
            background: #f1f5f9;
        }

        .button-group {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }

        .btn-primary {
            background: #667eea;
            color: white;
        }

        .btn-secondary {
            background: white;
            color: #667eea;
            border: 2px solid #667eea;
        }

        .btn-small {
            padding: 6px 12px;
            font-size: 0.875rem;
        }

        .timeline {
            position: relative;
            padding-left: 40px;
        }

        .timeline-item {
            position: relative;
            padding-bottom: 32px;
        }

        .timeline-item:last-child {
            padding-bottom: 0;
        }

        .timeline-marker {
            position: absolute;
            left: -40px;
            width: 32px;
            height: 32px;
            background: white;
            border: 3px solid #e2e8f0;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
        }

        .step-success .timeline-marker {
            border-color: #10b981;
        }

        .step-failure .timeline-marker {
            border-color: #ef4444;
        }

        .timeline-item::before {
            content: '';
            position: absolute;
            left: -25px;
            top: 32px;
            width: 2px;
            height: calc(100% - 12px);
            background: #e2e8f0;
        }

        .timeline-item:last-child::before {
            display: none;
        }

        .timeline-content {
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            border-left: 4px solid #e2e8f0;
        }

        .step-success .timeline-content {
            border-left-color: #10b981;
        }

        .step-failure .timeline-content {
            border-left-color: #ef4444;
            background: #fef2f2;
        }

        .timeline-header {
            display: flex;
            gap: 12px;
            margin-bottom: 12px;
            font-weight: 600;
        }

        .timeline-number {
            color: #667eea;
        }

        .timeline-action {
            color: #64748b;
            background: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.875rem;
        }

        .step-detail {
            margin-bottom: 8px;
            font-size: 0.9rem;
            color: #475569;
        }

        .step-detail:last-child {
            margin-bottom: 0;
        }

        .test-container {
            background: #1e293b;
            border-radius: 12px;
            overflow: hidden;
        }

        .test-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 16px 24px;
            background: #0f172a;
            border-bottom: 1px solid #334155;
        }

        .test-title {
            color: #e2e8f0;
            font-weight: 600;
        }

        .code-block {
            margin: 0;
            padding: 24px;
            background: #1e293b;
            color: #e2e8f0;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', monospace;
            font-size: 0.875rem;
            line-height: 1.6;
            overflow-x: auto;
            max-height: 600px;
        }

        .coverage-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }

        .coverage-item {
            background: #f8fafc;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }

        .coverage-label {
            font-size: 0.9rem;
            color: #64748b;
            margin-bottom: 8px;
        }

        .coverage-value {
            font-size: 2rem;
            font-weight: 700;
            color: #1e293b;
        }

        .coverage-subtext {
            font-size: 0.875rem;
            color: #94a3b8;
            margin-top: 4px;
        }

        .footer {
            background: #f8fafc;
            padding: 32px 40px;
            border-top: 1px solid #e2e8f0;
        }

        .footer-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
        }

        .powered-by {
            color: #64748b;
        }

        .footer-links {
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .footer-links a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }

        .footer-links a:hover {
            text-decoration: underline;
        }

        .separator {
            color: #cbd5e1;
        }

        @media (max-width: 768px) {
            .header h1 {
                font-size: 1.5rem;
            }

            .metrics {
                grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
                gap: 12px;
                padding: 20px;
            }

            section {
                padding: 24px;
            }

            .footer-content {
                flex-direction: column;
                text-align: center;
            }
        }
        """
    }

    // MARK: - JavaScript

    private var javascript: String {
        return """
        function copyCode(elementId) {
            const element = document.getElementById(elementId);
            const text = element.textContent;

            navigator.clipboard.writeText(text).then(() => {
                showToast('✅ Copied to clipboard!');
            }).catch(err => {
                console.error('Failed to copy:', err);
                showToast('❌ Failed to copy');
            });
        }

        function copyAllTests() {
            copyCode('all-tests');
        }

        function showToast(message) {
            const toast = document.createElement('div');
            toast.textContent = message;
            toast.style.cssText = `
                position: fixed;
                bottom: 24px;
                right: 24px;
                background: #1e293b;
                color: white;
                padding: 16px 24px;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.3);
                font-weight: 600;
                z-index: 1000;
                animation: slideIn 0.3s ease-out;
            `;

            document.body.appendChild(toast);

            setTimeout(() => {
                toast.style.animation = 'slideOut 0.3s ease-in';
                setTimeout(() => toast.remove(), 300);
            }, 2000);
        }

        const style = document.createElement('style');
        style.textContent = `
            @keyframes slideIn {
                from {
                    transform: translateX(400px);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }

            @keyframes slideOut {
                from {
                    transform: translateX(0);
                    opacity: 1;
                }
                to {
                    transform: translateX(400px);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
        """
    }

    // MARK: - Helper Functions

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }

    private func escapeHtml(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
