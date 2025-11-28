import Foundation

/// 탭 요청
public struct TapRequest: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let duration: TimeInterval?

    public init(x: Double, y: Double, duration: TimeInterval? = nil) {
        self.x = x
        self.y = y
        self.duration = duration
    }
}

/// 스와이프 요청
public struct SwipeRequest: Codable, Sendable {
    public let startX: Double
    public let startY: Double
    public let endX: Double
    public let endY: Double
    public let duration: TimeInterval

    public init(startX: Double, startY: Double, endX: Double, endY: Double, duration: TimeInterval = 0.5) {
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.duration = duration
    }
}

/// 텍스트 입력 요청
public struct InputTextRequest: Codable, Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

/// UI 트리 요청
public struct TreeRequest: Codable, Sendable {
    public let appBundleId: String?

    public init(appBundleId: String? = nil) {
        self.appBundleId = appBundleId
    }
}

/// 앱 실행 요청
public struct LaunchAppRequest: Codable, Sendable {
    public let bundleId: String

    public init(bundleId: String) {
        self.bundleId = bundleId
    }
}
