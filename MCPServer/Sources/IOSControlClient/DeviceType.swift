import Foundation

/// iOS 기기 타입
public enum DeviceType: String, Codable, Sendable {
    /// iOS 시뮬레이터
    case simulator
    /// 실제 iOS 기기 (USB/WiFi 연결)
    case physical
}
