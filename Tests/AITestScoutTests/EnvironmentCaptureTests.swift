import Foundation
import Testing
import CoreGraphics
@testable import AITestScout

/// Tests for EnvironmentCapture - Device/OS environment information
@Suite("EnvironmentCapture Tests")
struct EnvironmentCaptureTests {

    // MARK: - EnvironmentInfo Structure

    @Test("EnvironmentInfo initializes with all required fields")
    func testEnvironmentInfoInitialization() throws {
        let info = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone 15 Pro",
            screenResolution: CGSize(width: 393, height: 852),
            orientation: "portrait",
            locale: "en_US"
        )

        #expect(info.platform == "iOS")
        #expect(info.osVersion == "26.0")
        #expect(info.deviceModel == "iPhone 15 Pro")
        #expect(info.screenResolution == CGSize(width: 393, height: 852))
        #expect(info.orientation == "portrait")
        #expect(info.locale == "en_US")
    }

    @Test("EnvironmentInfo is Equatable")
    func testEnvironmentInfoEquatable() throws {
        let info1 = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone 15 Pro",
            screenResolution: CGSize(width: 393, height: 852),
            orientation: "portrait",
            locale: "en_US"
        )

        let info2 = EnvironmentInfo(
            platform: "iOS",
            osVersion: "26.0",
            deviceModel: "iPhone 15 Pro",
            screenResolution: CGSize(width: 393, height: 852),
            orientation: "portrait",
            locale: "en_US"
        )

        #expect(info1 == info2)
    }

    @Test("EnvironmentInfo is Codable")
    func testEnvironmentInfoCodable() throws {
        let original = EnvironmentInfo(
            platform: "macOS",
            osVersion: "14.0",
            deviceModel: "Mac mini",
            screenResolution: CGSize(width: 1920, height: 1080),
            orientation: "landscape",
            locale: "fr_FR"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        #expect(data.count > 0)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EnvironmentInfo.self, from: data)

        #expect(decoded == original)
        #expect(decoded.platform == "macOS")
        #expect(decoded.osVersion == "14.0")
        #expect(decoded.deviceModel == "Mac mini")
        #expect(decoded.screenResolution.width == 1920)
        #expect(decoded.screenResolution.height == 1080)
        #expect(decoded.orientation == "landscape")
        #expect(decoded.locale == "fr_FR")
    }

    // MARK: - Platform Detection

    @Test("EnvironmentCapture returns valid platform")
    func testPlatformCapture() throws {
        let environment = EnvironmentCapture.capture()

        // Platform should be either iOS or macOS
        #expect(environment.platform == "iOS" || environment.platform == "macOS")
    }

    @Test("OS version is not empty")
    func testOSVersionCapture() throws {
        let environment = EnvironmentCapture.capture()

        #expect(!environment.osVersion.isEmpty)
        #expect(environment.osVersion != "Unknown")
    }

    @Test("Device model is not empty")
    func testDeviceModelCapture() throws {
        let environment = EnvironmentCapture.capture()

        #expect(!environment.deviceModel.isEmpty)
        #expect(environment.deviceModel != "Unknown")
    }

    // MARK: - Screen Resolution

    @Test("Screen resolution is valid")
    func testScreenResolutionCapture() throws {
        let environment = EnvironmentCapture.capture()

        // Screen should have positive dimensions
        #expect(environment.screenResolution.width > 0)
        #expect(environment.screenResolution.height > 0)
    }

    @Test("Screen resolution is reasonable for modern devices")
    func testScreenResolutionReasonable() throws {
        let environment = EnvironmentCapture.capture()

        // Minimum reasonable resolution (iPhone SE)
        #expect(environment.screenResolution.width >= 320)
        #expect(environment.screenResolution.height >= 320)

        // Maximum reasonable resolution (8K displays)
        #expect(environment.screenResolution.width <= 8000)
        #expect(environment.screenResolution.height <= 8000)
    }

    // MARK: - Orientation

    @Test("Orientation is valid value")
    func testOrientationCapture() throws {
        let environment = EnvironmentCapture.capture()

        let validOrientations = ["portrait", "landscape", "unknown"]
        #expect(validOrientations.contains(environment.orientation))
    }

    // MARK: - Locale

    @Test("Locale is valid identifier")
    func testLocaleCapture() throws {
        let environment = EnvironmentCapture.capture()

        // Locale should follow standard format (e.g., en_US, fr_FR)
        #expect(!environment.locale.isEmpty)
        #expect(environment.locale.contains("_") || environment.locale.count == 2)
    }

    // MARK: - Consistency

    @Test("Multiple captures return consistent data")
    func testCaptureConsistency() throws {
        let capture1 = EnvironmentCapture.capture()
        let capture2 = EnvironmentCapture.capture()

        // Same device should return same info (within same run)
        #expect(capture1.platform == capture2.platform)
        #expect(capture1.deviceModel == capture2.deviceModel)
        #expect(capture1.screenResolution == capture2.screenResolution)
    }

    // MARK: - JSON Encoding

    @Test("Captured environment can be encoded to JSON")
    func testCaptureJSONEncoding() throws {
        let environment = EnvironmentCapture.capture()

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(environment)

        #expect(data.count > 0)

        // Verify JSON contains expected keys
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            #expect(json["platform"] != nil)
            #expect(json["osVersion"] != nil)
            #expect(json["deviceModel"] != nil)
            #expect(json["locale"] != nil)
        }
    }

    // MARK: - Real World Scenarios

    @Test("Environment suitable for test reproducibility")
    func testEnvironmentForTestReproducibility() throws {
        let environment = EnvironmentCapture.capture()

        // All critical fields should be populated for reproducing tests
        #expect(!environment.platform.isEmpty)
        #expect(!environment.osVersion.isEmpty)
        #expect(!environment.deviceModel.isEmpty)
        #expect(environment.screenResolution != .zero)
        #expect(!environment.locale.isEmpty)
    }

    @Test("Environment can be used in test report generation")
    func testEnvironmentForReportGeneration() throws {
        let environment = EnvironmentCapture.capture()

        // Verify all fields can be safely used in string formatting
        let report = """
        Test Environment:
        - Platform: \(environment.platform)
        - OS: \(environment.osVersion)
        - Device: \(environment.deviceModel)
        - Screen: \(Int(environment.screenResolution.width))×\(Int(environment.screenResolution.height))
        - Orientation: \(environment.orientation)
        - Locale: \(environment.locale)
        """

        #expect(!report.isEmpty)
        #expect(report.contains("Platform:"))
        #expect(report.contains("OS:"))
        #expect(report.contains("Device:"))
    }
}
