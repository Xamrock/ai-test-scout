import Foundation

/// Client for Anthropic's Claude API
public final class ClaudeClient: LLMClient {
    private let configuration: LLMClientConfiguration
    private let session: URLSession
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    public init(configuration: LLMClientConfiguration) {
        self.configuration = configuration

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        self.session = URLSession(configuration: config)
    }

    public func generateCompletion(prompt: String, model: String?) async throws -> LLMResponse {
        guard configuration.isValid else {
            throw LLMError.invalidAPIKey
        }

        let modelToUse = model ?? configuration.defaultModel

        // Build request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        // Build request body
        let requestBody: [String: Any] = [
            "model": modelToUse,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Execute request with retries
        return try await executeWithRetry {
            try await self.performRequest(request)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> LLMResponse {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(URLError(.badServerResponse))
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw LLMError.rateLimitExceeded
        }

        // Handle errors
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse("Invalid JSON response")
        }

        // Extract content
        guard let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw LLMError.invalidResponse("Missing content in response")
        }

        // Extract model
        let responseModel = json["model"] as? String ?? configuration.defaultModel

        // Extract usage
        let usage: TokenUsage
        if let usageData = json["usage"] as? [String: Any],
           let inputTokens = usageData["input_tokens"] as? Int,
           let outputTokens = usageData["output_tokens"] as? Int {
            usage = TokenUsage(
                promptTokens: inputTokens,
                completionTokens: outputTokens,
                totalTokens: inputTokens + outputTokens
            )
        } else {
            usage = TokenUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0)
        }

        return LLMResponse(content: text, model: responseModel, usage: usage)
    }

    private func executeWithRetry<T>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<configuration.maxRetries {
            do {
                return try await operation()
            } catch LLMError.rateLimitExceeded {
                // Wait longer for rate limits
                let delay = configuration.retryDelay * Double(attempt + 1) * 2
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                lastError = LLMError.rateLimitExceeded
            } catch {
                if attempt < configuration.maxRetries - 1 {
                    // Wait before retry
                    try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
                }
                lastError = error
            }
        }

        throw lastError ?? LLMError.apiError("All retries failed")
    }
}
