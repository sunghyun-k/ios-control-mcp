import Foundation
import Common

/// Agent 클라이언트 공통 프로토콜
/// 시뮬레이터와 실기기 모두에서 동일한 인터페이스로 Agent와 통신
public protocol AgentClient: Sendable {
    // MARK: - Status
    func status() async throws -> StatusResponse
    func isServerRunning() async -> Bool

    // MARK: - UI Query
    func tree(appBundleId: String?) async throws -> TreeResponse
    func foregroundApp() async throws -> ForegroundAppResponse
    func screenshot(format: String) async throws -> Data

    // MARK: - Touch/Gestures
    func tap(_ request: TapRequest) async throws
    func swipe(_ request: SwipeRequest) async throws
    func pinch(_ request: PinchRequest) async throws

    // MARK: - Input
    func inputText(_ request: InputTextRequest) async throws

    // MARK: - App Control
    func launchApp(bundleId: String) async throws
    func goHome() async throws

    // MARK: - Device Info (simctl-based, simulator only)
    func listApps() async throws -> ListAppsResponse
}

// MARK: - Default implementations for optional features

extension AgentClient {
    public func listApps() async throws -> ListAppsResponse {
        throw AgentClientError.notSupportedOnPhysicalDevice("listApps")
    }

    public func isServerRunning() async -> Bool {
        do {
            _ = try await status()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Convenience methods with default implementations

extension AgentClient {
    /// 탭 (좌표 직접 지정)
    public func tap(x: Double, y: Double, duration: TimeInterval? = nil) async throws {
        try await tap(TapRequest(x: x, y: y, duration: duration))
    }

    /// 스와이프 (좌표 직접 지정)
    public func swipe(startX: Double, startY: Double, endX: Double, endY: Double, duration: TimeInterval = 0.5, holdDuration: TimeInterval? = nil, liftDelay: TimeInterval? = nil) async throws {
        try await swipe(SwipeRequest(startX: startX, startY: startY, endX: endX, endY: endY, duration: duration, holdDuration: holdDuration, liftDelay: liftDelay))
    }

    /// 핀치 (좌표 직접 지정)
    public func pinch(x: Double, y: Double, scale: Double, velocity: Double = 1.0) async throws {
        try await pinch(PinchRequest(x: x, y: y, scale: scale, velocity: velocity))
    }

    /// 텍스트 입력 (문자열 직접 지정)
    public func inputText(_ text: String) async throws {
        try await inputText(InputTextRequest(text: text))
    }

    /// UI 트리 조회 (기본값)
    public func tree() async throws -> TreeResponse {
        try await tree(appBundleId: nil)
    }

    /// 스크린샷 (기본 PNG 포맷)
    public func screenshot() async throws -> Data {
        try await screenshot(format: "png")
    }
}

public enum AgentClientError: Error, LocalizedError {
    case notSupportedOnPhysicalDevice(String)

    public var errorDescription: String? {
        switch self {
        case .notSupportedOnPhysicalDevice(let feature):
            return "\(feature) is not supported on physical devices (requires simctl)"
        }
    }
}

// MARK: - NoOp Client

/// Agent 연결 없이 동작하는 도구용 더미 클라이언트
public struct NoOpAgentClient: AgentClient {
    public init() {}

    public func status() async throws -> StatusResponse {
        throw AgentClientError.notSupportedOnPhysicalDevice("status")
    }

    public func tree(appBundleId: String?) async throws -> TreeResponse {
        throw AgentClientError.notSupportedOnPhysicalDevice("tree")
    }

    public func foregroundApp() async throws -> ForegroundAppResponse {
        throw AgentClientError.notSupportedOnPhysicalDevice("foregroundApp")
    }

    public func screenshot(format: String) async throws -> Data {
        throw AgentClientError.notSupportedOnPhysicalDevice("screenshot")
    }

    public func tap(_ request: TapRequest) async throws {
        throw AgentClientError.notSupportedOnPhysicalDevice("tap")
    }

    public func swipe(_ request: SwipeRequest) async throws {
        throw AgentClientError.notSupportedOnPhysicalDevice("swipe")
    }

    public func pinch(_ request: PinchRequest) async throws {
        throw AgentClientError.notSupportedOnPhysicalDevice("pinch")
    }

    public func inputText(_ request: InputTextRequest) async throws {
        throw AgentClientError.notSupportedOnPhysicalDevice("inputText")
    }

    public func launchApp(bundleId: String) async throws {
        throw AgentClientError.notSupportedOnPhysicalDevice("launchApp")
    }

    public func goHome() async throws {
        throw AgentClientError.notSupportedOnPhysicalDevice("goHome")
    }
}
