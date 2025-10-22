import Foundation
import XCTest

/// Extension to XCTestCase for bridging async/await to synchronous test methods
extension XCTestCase {

    /// Execute an async throwing closure synchronously
    ///
    /// This helper eliminates the boilerplate of creating XCTestExpectation
    /// and waiting for async operations in XCTest methods.
    ///
    /// - Parameter block: Async throwing closure to execute
    /// - Returns: The result of the async closure
    /// - Throws: Any error thrown by the async closure
    ///
    /// **Example usage:**
    /// ```swift
    /// func testAICrawler() throws {
    ///     let crawler = try xcAwait { try await AICrawler() }
    ///     let decision = try xcAwait { try await crawler.decideNextAction(...) }
    /// }
    /// ```
    ///
    /// **Before (35+ lines with boilerplate):**
    /// ```swift
    /// private func awaitAsync<T>(_ block: @escaping () async throws -> T) throws -> T {
    ///     let expectation = XCTestExpectation()
    ///     var result: T?
    ///     Task { result = try await block(); expectation.fulfill() }
    ///     wait(for: [expectation], timeout: 30)
    ///     return result!
    /// }
    /// ```
    ///
    /// **After (1 line):**
    /// ```swift
    /// let result = try xcAwait { try await asyncOperation() }
    /// ```
    nonisolated public func xcAwait<T>(
        timeout: TimeInterval = 300.0, // 5 minutes default for AI operations
        _ block: @escaping @Sendable () async throws -> T
    ) throws -> T where T: Sendable {
        let expectation = XCTestExpectation(description: "Async operation")

        nonisolated(unsafe) var result: Result<T, Error>?

        Task { @Sendable in
            do {
                let value = try await block()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            expectation.fulfill()
        }

        // Wait for async operation to complete
        let waitResult = XCTWaiter().wait(for: [expectation], timeout: timeout)

        // Check if wait completed successfully
        guard waitResult == .completed, let finalResult = result else {
            throw NSError(domain: "XCTestCase+Async", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Async operation failed to complete after \(timeout) seconds (wait result: \(waitResult))"
            ])
        }

        // Return result or rethrow error
        return try finalResult.get()
    }
}
