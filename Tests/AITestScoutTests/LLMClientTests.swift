import Foundation
import Testing
@testable import AITestScout

/// Tests for LLM Client abstraction and implementations
@Suite("LLM Client Tests")
struct LLMClientTests {

    // MARK: - Mock LLM Client for Testing

    final class MockLLMClient: LLMClient, @unchecked Sendable {
        var shouldFail = false
        var responseDelay: TimeInterval = 0
        var mockResponse: String = "Generated test code"
        var capturedPrompts: [String] = []

        func generateCompletion(prompt: String, model: String?) async throws -> LLMResponse {
            capturedPrompts.append(prompt)

            if shouldFail {
                throw LLMError.apiError("Mock API error")
            }

            if responseDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
            }

            return LLMResponse(
                content: mockResponse,
                model: model ?? "mock-model",
                usage: TokenUsage(promptTokens: 100, completionTokens: 200, totalTokens: 300)
            )
        }
    }

    // MARK: - Protocol Tests

    @Test("LLMClient protocol should be async")
    func testProtocolIsAsync() async throws {
        let client = MockLLMClient()
        let response = try await client.generateCompletion(prompt: "test", model: nil)

        #expect(response.content == "Generated test code")
    }

    @Test("LLMClient should capture prompts")
    func testClientCapturesPrompts() async throws {
        let client = MockLLMClient()

        _ = try await client.generateCompletion(prompt: "First prompt", model: nil)
        _ = try await client.generateCompletion(prompt: "Second prompt", model: nil)

        #expect(client.capturedPrompts.count == 2)
        #expect(client.capturedPrompts[0] == "First prompt")
        #expect(client.capturedPrompts[1] == "Second prompt")
    }

    @Test("LLMClient should handle errors")
    func testClientHandlesErrors() async throws {
        let client = MockLLMClient()
        client.shouldFail = true

        do {
            _ = try await client.generateCompletion(prompt: "test", model: nil)
            #expect(Bool(false), "Should have thrown error")
        } catch {
            #expect(error is LLMError)
        }
    }

    @Test("LLMResponse should include model and usage info")
    func testResponseIncludesMetadata() async throws {
        let client = MockLLMClient()
        let response = try await client.generateCompletion(prompt: "test", model: "gpt-4")

        #expect(response.model == "gpt-4")
        #expect(response.usage.totalTokens == 300)
        #expect(response.usage.promptTokens == 100)
        #expect(response.usage.completionTokens == 200)
    }

    // MARK: - Configuration Tests

    @Test("LLMClientConfiguration should validate API keys")
    func testConfigurationValidatesAPIKeys() throws {
        // Empty API key should be invalid
        let emptyConfig = LLMClientConfiguration(apiKey: "", provider: .claude)
        #expect(!emptyConfig.isValid)

        // Valid API key
        let validConfig = LLMClientConfiguration(apiKey: "sk-test-key", provider: .claude)
        #expect(validConfig.isValid)
    }

    @Test("LLMClientConfiguration should support different providers")
    func testConfigurationSupportsProviders() throws {
        let claudeConfig = LLMClientConfiguration(apiKey: "key", provider: .claude)
        #expect(claudeConfig.provider == .claude)

        let openAIConfig = LLMClientConfiguration(apiKey: "key", provider: .openAI)
        #expect(openAIConfig.provider == .openAI)
    }

    @Test("LLMClientConfiguration should have default models")
    func testConfigurationHasDefaultModels() throws {
        let claudeConfig = LLMClientConfiguration(apiKey: "key", provider: .claude)
        #expect(claudeConfig.defaultModel.contains("claude"))

        let openAIConfig = LLMClientConfiguration(apiKey: "key", provider: .openAI)
        #expect(openAIConfig.defaultModel.contains("gpt"))
    }

    // MARK: - Error Handling Tests

    @Test("LLMError should have descriptive cases")
    func testErrorCases() throws {
        let apiError = LLMError.apiError("API failed")
        #expect("\(apiError)".contains("API failed"))

        let invalidKeyError = LLMError.invalidAPIKey
        #expect("\(invalidKeyError)".lowercased().contains("api key"))

        let rateLimitError = LLMError.rateLimitExceeded
        #expect("\(rateLimitError)".lowercased().contains("rate limit"))

        let invalidResponseError = LLMError.invalidResponse("Bad JSON")
        #expect("\(invalidResponseError)".contains("Bad JSON"))
    }

    // MARK: - Retry Logic Tests

    @Test("LLMClient should support retry configuration")
    func testRetryConfiguration() throws {
        var config = LLMClientConfiguration(apiKey: "key", provider: .claude)
        config.maxRetries = 3
        config.retryDelay = 1.0

        #expect(config.maxRetries == 3)
        #expect(config.retryDelay == 1.0)
    }

    // MARK: - Token Usage Tests

    @Test("TokenUsage should calculate total correctly")
    func testTokenUsageCalculation() throws {
        let usage = TokenUsage(promptTokens: 150, completionTokens: 250, totalTokens: 400)

        #expect(usage.promptTokens == 150)
        #expect(usage.completionTokens == 250)
        #expect(usage.totalTokens == 400)
    }

    @Test("TokenUsage should be Codable")
    func testTokenUsageIsCodable() throws {
        let original = TokenUsage(promptTokens: 100, completionTokens: 200, totalTokens: 300)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TokenUsage.self, from: data)

        #expect(decoded.totalTokens == original.totalTokens)
    }

    // MARK: - Real Client Tests (require API keys)

    @Test("ClaudeClient should initialize with configuration")
    func testClaudeClientInitialization() throws {
        let config = LLMClientConfiguration(
            apiKey: "test-key",
            provider: .claude
        )

        let client = ClaudeClient(configuration: config)
        _ = client // Suppress unused warning
    }

    @Test("OpenAIClient should initialize with configuration")
    func testOpenAIClientInitialization() throws {
        let config = LLMClientConfiguration(
            apiKey: "test-key",
            provider: .openAI
        )

        let client = OpenAIClient(configuration: config)
        _ = client // Suppress unused warning
    }

    // MARK: - Factory Tests

    @Test("LLMClient factory should create correct client type")
    func testFactoryCreatesCorrectClient() throws {
        let claudeConfig = LLMClientConfiguration(apiKey: "key", provider: .claude)
        let claudeClient = LLMClientFactory.createClient(configuration: claudeConfig)
        #expect(claudeClient is ClaudeClient)

        let openAIConfig = LLMClientConfiguration(apiKey: "key", provider: .openAI)
        let openAIClient = LLMClientFactory.createClient(configuration: openAIConfig)
        #expect(openAIClient is OpenAIClient)
    }

    // MARK: - Integration Tests (Skipped without API keys)

    @Test("ClaudeClient should generate completions", .disabled("Requires API key"))
    func testClaudeClientGeneratesCompletions() async throws {
        // This test would require a real API key
        // Skipped in CI, can be run locally with ANTHROPIC_API_KEY env var
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] else {
            return
        }

        let config = LLMClientConfiguration(apiKey: apiKey, provider: .claude)
        let client = ClaudeClient(configuration: config)

        let response = try await client.generateCompletion(
            prompt: "Say 'test successful' and nothing else.",
            model: "claude-3-5-sonnet-20241022"
        )

        #expect(response.content.lowercased().contains("test successful"))
        #expect(response.usage.totalTokens > 0)
    }

    @Test("OpenAIClient should generate completions", .disabled("Requires API key"))
    func testOpenAIClientGeneratesCompletions() async throws {
        // This test would require a real API key
        // Skipped in CI, can be run locally with OPENAI_API_KEY env var
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            return
        }

        let config = LLMClientConfiguration(apiKey: apiKey, provider: .openAI)
        let client = OpenAIClient(configuration: config)

        let response = try await client.generateCompletion(
            prompt: "Say 'test successful' and nothing else.",
            model: "gpt-4"
        )

        #expect(response.content.lowercased().contains("test successful"))
        #expect(response.usage.totalTokens > 0)
    }
}
