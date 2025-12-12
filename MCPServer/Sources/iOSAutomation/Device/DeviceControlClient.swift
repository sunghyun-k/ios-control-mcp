import Foundation

/// devicectl 명령 실행기
/// 실기기 정보를 조회합니다.
public struct DeviceControlClient: Sendable {
    private let xcrunPath = "/usr/bin/xcrun"

    public init() {}

    // MARK: - 기기 목록

    /// devicectl로 연결된 실기기 목록 조회 (iOS/iPadOS만)
    public func listDevices() throws -> [Device] {
        let data = try runWithJSONOutput(["list", "devices"])
        let response = try JSONDecoder().decode(DeviceCtlResponse.self, from: data)
        return response.result.devices.filter(\.isIOSDevice)
    }

    /// UDID로 기기 찾기
    public func findDevice(udid: String) throws -> Device? {
        let devices = try listDevices()
        return devices.first { $0.hardwareUdid == udid }
    }

    // MARK: - Private

    /// devicectl 명령 실행 (JSON 출력)
    private func runWithJSONOutput(_ arguments: [String]) throws -> Data {
        let tempFile = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString + ".json")

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        let process = Process()
        process.executableURL = URL(filePath: xcrunPath)
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
}

// MARK: - Errors

public enum DeviceCtlError: Error, LocalizedError {
    case commandFailed(exitCode: Int32)
    case parseError

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let exitCode):
            "devicectl command failed with exit code \(exitCode)"
        case .parseError:
            "Failed to parse devicectl output"
        }
    }
}

// MARK: - JSON Response Models

/// devicectl list devices --json-output 응답 구조
private struct DeviceCtlResponse: Decodable {
    let result: DeviceCtlResult
}

private struct DeviceCtlResult: Decodable {
    let devices: [Device]
}

/// devicectl에서 조회한 기기 정보
public struct Device: Decodable, Sendable {
    /// CoreDevice UUID
    public let identifier: String
    let hardwareProperties: HardwareProperties?
    let deviceProperties: DeviceProperties?
    let connectionProperties: ConnectionProperties?

    struct HardwareProperties: Decodable {
        let platform: String?
        let udid: String?
        let marketingName: String?
        let productType: String?
        let serialNumber: String?
    }

    struct DeviceProperties: Decodable {
        let name: String?
        let osVersionNumber: String?
    }

    struct ConnectionProperties: Decodable {
        let tunnelState: String?
        let transportType: String?
        let pairingState: String?
    }
}

// MARK: - Device Computed Properties

extension Device {
    /// 하드웨어 UDID (usbmuxd의 SerialNumber와 동일)
    public var hardwareUdid: String? { hardwareProperties?.udid }

    /// 기기 이름
    public var name: String { deviceProperties?.name ?? "Unknown" }

    /// 모델 (예: "iPad Pro 11-inch (M4)")
    public var model: String {
        hardwareProperties?.marketingName
            ?? hardwareProperties?.productType
            ?? "Unknown"
    }

    /// 플랫폼 (예: "iOS", "iPadOS")
    public var platform: String { hardwareProperties?.platform ?? "" }

    /// OS 버전
    public var osVersion: String? { deviceProperties?.osVersionNumber }

    /// 연결 상태 (예: "connected", "available")
    public var connectionState: String { connectionProperties?.tunnelState ?? "unknown" }

    /// 연결 타입 (예: "wired", "localNetwork")
    public var transportType: String { connectionProperties?.transportType ?? "unknown" }

    /// 시리얼 번호
    public var serialNumber: String? { hardwareProperties?.serialNumber }

    /// 페어링 상태
    public var pairingState: String? { connectionProperties?.pairingState }

    /// 연결됨 여부
    public var isConnected: Bool { connectionState == "connected" }

    /// USB 연결 여부
    public var isWired: Bool { transportType == "wired" }

    /// iOS/iPadOS 기기 여부
    public var isIOSDevice: Bool { platform == "iOS" || platform == "iPadOS" }
}
