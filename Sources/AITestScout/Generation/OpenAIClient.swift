import Foundation

/// Client for OpenAI's API
public final class OpenAIClient: LLMClient {
    private let configuration: LLMClientConfiguration
    private let session: URLSession
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

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
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        let requestBody: [String: Any] = [
            "model": modelToUse,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 4096
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
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse("Missing content in response")
        }

        // Extract model
        let responseModel = json["model"] as? String ?? configuration.defaultModel

        // Extract usage
        let usage: TokenUsage
        if let usageData = json["usage"] as? [String: Any],
           let promptTokens = usageData["prompt_tokens"] as? Int,
           let completionTokens = usageData["completion_tokens"] as? Int,
           let totalTokens = usageData["total_tokens"] as? Int {
            usage = TokenUsage(
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                totalTokens: totalTokens
            )
        } else {
            usage = TokenUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0)
        }

        return LLMResponse(content: content, model: responseModel, usage: usage)
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
