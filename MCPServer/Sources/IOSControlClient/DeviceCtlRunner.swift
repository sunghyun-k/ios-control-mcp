import Foundation

/// devicectl 명령 실행기
/// 실기기 정보를 조회합니다.
public struct DeviceCtlRunner: Sendable {
    public static let shared = DeviceCtlRunner()

    private let xcrunPath = "/usr/bin/xcrun"

    public init() {}

    // MARK: - 기기 목록

    /// devicectl로 연결된 실기기 목록 조회
    public func listDevices() throws -> [DeviceCtlDeviceInfo] {
        let data = try runWithJSONOutput(["list", "devices"])
        return try parseDeviceList(from: data)
    }

    /// UDID로 기기 찾기
    public func findDevice(udid: String) throws -> DeviceCtlDeviceInfo? {
        let devices = try listDevices()
        return devices.first { $0.hardwareUdid == udid }
    }

    // MARK: - Private Methods

    /// devicectl 명령 실행 (JSON 출력)
    private func runWithJSONOutput(_ arguments: [String]) throws -> Data {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["devicectl"] + arguments + ["--json-output", tempFile.path]

        // devicectl은 표준 출력에 테이블 형식도 출력하므로 무시
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw DeviceCtlError.commandFailed(exitCode: process.terminationStatus)
        }

        return try Data(contentsOf: tempFile)
    }

    /// JSON 파싱
    private func parseDeviceList(from data: Data) throws -> [DeviceCtlDeviceInfo] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let devices = result["devices"] as? [[String: Any]] else {
            return []
        }

        return devices.compactMap { DeviceCtlDeviceInfo.from(json: $0) }
    }
}

// MARK: - DeviceCtlDeviceInfo

/// devicectl에서 조회한 기기 정보
public struct DeviceCtlDeviceInfo: Sendable {
    /// CoreDevice UUID (예: FA4F89C5-44AF-528D-BD6A-91E307D6DE04)
    public let coreDeviceId: String

    /// 하드웨어 UDID (예: 00008132-001C450E1A39001C)
    /// usbmuxd의 SerialNumber와 동일
    public let hardwareUdid: String

    /// 기기 이름 (예: "skipadm4", "My iPhone")
    public let name: String

    /// 모델 (예: "iPad Pro 11-inch (M4)")
    public let model: String

    /// 플랫폼 (예: "iOS", "iPadOS")
    public let platform: String

    /// OS 버전 (예: "18.1")
    public let osVersion: String?

    /// 연결 상태 (예: "connected", "available")
    public let connectionState: String

    /// 연결 타입 (예: "wired", "localNetwork")
    public let transportType: String

    /// 시리얼 번호 (예: "TQWD2WT34N")
    public let serialNumber: String?

    /// 페어링 상태 (예: "paired")
    public let pairingState: String?

    /// JSON에서 파싱
    public static func from(json: [String: Any]) -> DeviceCtlDeviceInfo? {
        guard let identifier = json["identifier"] as? String else { return nil }

        let hardwareProps = json["hardwareProperties"] as? [String: Any] ?? [:]
        let deviceProps = json["deviceProperties"] as? [String: Any] ?? [:]
        let connectionProps = json["connectionProperties"] as? [String: Any] ?? [:]

        // iOS/iPadOS 기기만 필터링
        let platform = hardwareProps["platform"] as? String ?? ""
        guard platform == "iOS" || platform == "iPadOS" else { return nil }

        guard let hardwareUdid = hardwareProps["udid"] as? String else { return nil }

        // tunnelState로 연결 상태 확인 (connected, disconnected 등)
        let tunnelState = connectionProps["tunnelState"] as? String ?? "unknown"

        return DeviceCtlDeviceInfo(
            coreDeviceId: identifier,
            hardwareUdid: hardwareUdid,
            name: deviceProps["name"] as? String ?? "Unknown",
            model: hardwareProps["marketingName"] as? String
                ?? hardwareProps["productType"] as? String
                ?? "Unknown",
            platform: platform,
            osVersion: deviceProps["osVersionNumber"] as? String,
            connectionState: tunnelState,
            transportType: connectionProps["transportType"] as? String ?? "unknown",
            serialNumber: hardwareProps["serialNumber"] as? String,
            pairingState: connectionProps["pairingState"] as? String
        )
    }

    /// 연결됨 여부 (tunnelState가 connected인 경우)
    public var isConnected: Bool {
        connectionState == "connected"
    }

    /// USB 연결 여부
    public var isWired: Bool {
        transportType == "wired"
    }
}

// MARK: - Errors

public enum DeviceCtlError: Error, LocalizedError {
    case commandFailed(exitCode: Int32)
    case parseError

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let exitCode):
            return "devicectl command failed with exit code \(exitCode)"
        case .parseError:
            return "Failed to parse devicectl output"
        }
    }
}
