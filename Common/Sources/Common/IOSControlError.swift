import Foundation

/// IOSControl 통합 오류 타입
public enum IOSControlError: Error, LocalizedError {
    // MARK: - Server
    case serverNotRunning
    case serverTimeout(TimeInterval)

    // MARK: - HTTP
    case httpError(Int)
    case invalidResponse

    // MARK: - Element
    case elementNotFound(String)

    // MARK: - Simulator
    case simulatorNotFound
    case simulatorBootFailed(udid: String, exitCode: Int)
    case simulatorBootTimeout(udid: String, timeout: TimeInterval)

    // MARK: - simctl
    case simctlError(command: String, exitCode: Int32)
    case simctlAppNotFound
    case simctlInstallFailed(exitCode: Int)
    case simctlLaunchFailed(exitCode: Int)

    // MARK: - Arguments
    case missingArgument(String)
    case invalidArgumentType(key: String, expected: String)

    // MARK: - Tools
    case unknownTool(String)

    public var errorDescription: String? {
        switch self {
        // Server
        case .serverNotRunning:
            return """
                AutomationServer is not running.

                Solutions:
                  1. Check if the device/simulator is powered on
                  2. Retry - the Agent will start automatically
                  3. If the problem persists, reboot the device
                """
        case .serverTimeout(let seconds):
            return """
                AutomationServer did not start within \(Int(seconds)) seconds.

                Solutions:
                  1. Check if the device/simulator screen is unlocked
                  2. For physical devices, check for "Untrusted Developer" warning
                     → Settings → General → VPN & Device Management → Trust the app
                  3. Reboot the device and retry
                """

        // HTTP
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidResponse:
            return "Invalid response"

        // Element
        case .elementNotFound(let label):
            return "Element not found: \(label)"

        // Simulator
        case .simulatorNotFound:
            return """
                No available iPhone simulator found.

                Solutions:
                  1. Check if Xcode is installed
                  2. Download iOS simulator runtime: xcodebuild -downloadPlatform iOS
                  3. Check Xcode → Settings → Platforms for iOS simulator
                """
        case .simulatorBootFailed(let udid, let code):
            return """
                Simulator boot failed: \(udid), exit code: \(code)

                Solutions:
                  1. Check iOS runtime installation in Xcode → Settings → Platforms
                  2. Delete and recreate the device in Simulator app
                  3. Reset simulator with: xcrun simctl erase \(udid)
                """
        case .simulatorBootTimeout(let udid, let timeout):
            return """
                Simulator \(udid) did not boot within \(Int(timeout)) seconds.

                Solutions:
                  1. Open Simulator app directly to check boot status
                  2. Restart Mac and retry
                  3. Try a different simulator
                """

        // simctl
        case .simctlError(let command, let code):
            return "simctl \(command) failed, exit code: \(code)"
        case .simctlAppNotFound:
            return """
                AutomationServer app not found.

                It will be built automatically on first run.
                Check if Xcode is installed.
                """
        case .simctlInstallFailed(let code):
            return """
                App installation failed, exit code: \(code)

                Solutions:
                  1. Check if the simulator is booted
                  2. Reboot the simulator and retry
                """
        case .simctlLaunchFailed(let code):
            return """
                App launch failed, exit code: \(code)

                Solutions:
                  1. Check if the app is installed on the simulator
                  2. Reboot the simulator and retry
                """

        // Arguments
        case .missingArgument(let key):
            return "Missing required argument: '\(key)'"
        case .invalidArgumentType(let key, let expected):
            return "Invalid type for argument '\(key)'. Expected: \(expected)"

        // Tools
        case .unknownTool(let name):
            return "Unknown tool: \(name)"
        }
    }
}
