import Foundation

/// iOS 기기 정보
public struct DeviceInfo: Codable, Sendable, Identifiable, Equatable {
    /// 기기 UDID (고유 식별자)
    public let id: String
    /// 기기 이름 (예: "iPhone 15 Pro", "My iPhone")
    public let name: String
    /// 기기 타입 (시뮬레이터/실기기)
    public let type: DeviceType
    /// 연결 상태
    public let isConnected: Bool
    /// iOS 버전 (예: "17.0", "18.1")
    public let osVersion: String?
    /// 기기 모델 (예: "iPhone15,2")
    public let model: String?

    public init(
        id: String,
        name: String,
        type: DeviceType,
        isConnected: Bool,
        osVersion: String? = nil,
        model: String? = nil,
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isConnected = isConnected
        self.osVersion = osVersion
        self.model = model
    }
}
