import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Captures environment information for test reproducibility
///
/// Records device/OS context so LLMs can generate tests that account for
/// environment-specific behavior and reproduce issues accurately.
///
/// Example:
/// ```swift
/// let env = EnvironmentCapture.capture()
/// print("Running on \(env.deviceModel) with iOS \(env.osVersion)")
/// ```
public struct EnvironmentInfo: Codable, Equatable {
    /// Platform name ("iOS" or "macOS")
    public let platform: String

    /// Operating system version (e.g., "26.0", "15.0")
    public let osVersion: String

    /// Device model (e.g., "iPhone 15 Pro", "Mac mini")
    public let deviceModel: String

    /// Screen resolution in points
    public let screenResolution: CGSize

    /// Current orientation ("portrait", "landscape", "unknown")
    public let orientation: String

    /// Locale identifier (e.g., "en_US", "fr_FR")
    public let locale: String

    public init(
        platform: String,
        osVersion: String,
        deviceModel: String,
        screenResolution: CGSize,
        orientation: String,
        locale: String
    ) {
        self.platform = platform
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.screenResolution = screenResolution
        self.orientation = orientation
        self.locale = locale
    }
}

/// Utility for capturing current environment information
public enum EnvironmentCapture {

    /// Captures current environment details
    /// - Returns: EnvironmentInfo with current device/OS context
    public static func capture() -> EnvironmentInfo {
        #if os(iOS)
        return captureiOS()
        #elseif os(macOS)
        return capturemacOS()
        #else
        return EnvironmentInfo(
            platform: "Unknown",
            osVersion: "Unknown",
            deviceModel: "Unknown",
            screenResolution: CGSize.zero,
            orientation: "unknown",
            locale: Locale.current.identifier
        )
        #endif
    }

    #if os(iOS)
    private static func captureiOS() -> EnvironmentInfo {
        let device = UIDevice.current
        let screen = UIScreen.main

        let orientation: String
        switch screen.bounds.width < screen.bounds.height {
        case true: orientation = "portrait"
        case false: orientation = "landscape"
        }

        return EnvironmentInfo(
            platform: "iOS",
            osVersion: device.systemVersion,
            deviceModel: device.model,
            screenResolution: screen.bounds.size,
            orientation: orientation,
            locale: Locale.current.identifier
        )
    }
    #endif

    #if os(macOS)
    private static func capturemacOS() -> EnvironmentInfo {
        let processInfo = ProcessInfo.processInfo
        let osVersion = processInfo.operatingSystemVersionString

        // Get screen resolution from main screen
        let screenSize: CGSize
        if let screen = NSScreen.main {
            screenSize = screen.frame.size
        } else {
            screenSize = CGSize(width: 1920, height: 1080) // Default fallback
        }

        return EnvironmentInfo(
            platform: "macOS",
            osVersion: osVersion,
            deviceModel: "Mac",  // Generic, could be enhanced with sysctl
            screenResolution: screenSize,
            orientation: "landscape",  // macOS is always landscape
            locale: Locale.current.identifier
        )
    }
    #endif
}
