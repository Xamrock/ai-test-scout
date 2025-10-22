import Foundation

/// Protocol for LLM providers (Claude, OpenAI, etc.)
public protocol LLMClient: Sendable {
    /// Generate a completion from a prompt
    /// - Parameters:
    ///   - prompt: The prompt to send to the LLM
    ///   - model: Optional model override (uses default if nil)
    /// - Returns: The LLM's response with metadata
    /// - Throws: LLMError if the request fails
    func generateCompletion(prompt: String, model: String?) async throws -> LLMResponse
}

/// Response from an LLM
public struct LLMResponse: Codable, Sendable {
    /// The generated text content
    public let content: String

    /// The model that generated the response
    public let model: String

    /// Token usage information
    public let usage: TokenUsage

    public init(content: String, model: String, usage: TokenUsage) {
        self.content = content
        self.model = model
        self.usage = usage
    }
}

/// Token usage information
public struct TokenUsage: Codable, Sendable {
    /// Number of tokens in the prompt
    public let promptTokens: Int

    /// Number of tokens in the completion
    public let completionTokens: Int

    /// Total tokens used
    public let totalTokens: Int

    public init(promptTokens: Int, completionTokens: Int, totalTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}

/// Errors that can occur when using LLM clients
public enum LLMError: Error, CustomStringConvertible {
    case invalidAPIKey
    case apiError(String)
    case rateLimitExceeded
    case invalidResponse(String)
    case networkError(Error)

    public var description: String {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .apiError(let message):
            return "API error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// LLM provider type
public enum LLMProvider: String, Codable, Sendable {
    case claude
    case openAI
}

/// Configuration for LLM clients
public struct LLMClientConfiguration: Sendable {
    /// API key for the provider
    public let apiKey: String

    /// The LLM provider
    public let provider: LLMProvider

    /// Maximum number of retries for failed requests
    public var maxRetries: Int

    /// Delay between retries in seconds
    public var retryDelay: TimeInterval

    /// Timeout for requests in seconds
    public var timeout: TimeInterval

    /// Default model to use
    public var defaultModel: String {
        switch provider {
        case .claude:
            return "claude-3-5-sonnet-20241022"
        case .openAI:
            return "gpt-4-turbo-preview"
        }
    }

    /// Whether the configuration is valid
    public var isValid: Bool {
        return !apiKey.isEmpty
    }

    public init(
        apiKey: String,
        provider: LLMProvider,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        timeout: TimeInterval = 60.0
    ) {
        self.apiKey = apiKey
        self.provider = provider
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.timeout = timeout
    }
}

/// Factory for creating LLM clients
public enum LLMClientFactory {
    /// Create an LLM client from configuration
    /// - Parameter configuration: The client configuration
    /// - Returns: An LLM client instance
    public static func createClient(configuration: LLMClientConfiguration) -> any LLMClient {
        switch configuration.provider {
        case .claude:
            return ClaudeClient(configuration: configuration)
        case .openAI:
            return OpenAIClient(configuration: configuration)
        }
    }
}
