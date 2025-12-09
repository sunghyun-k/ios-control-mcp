import Foundation

/// 기기 관리자
/// 시뮬레이터와 실제 iOS 기기를 통합 관리합니다.
public actor DeviceManager {
    /// 싱글톤 인스턴스
    public static let shared = DeviceManager()

    /// 에이전트 포트 번호
    private static let agentPort: UInt16 = 22087

    private let simctlRunner = SimctlRunner.shared
    private let deviceCtlRunner = DeviceCtlRunner.shared

    private var currentDeviceId: String?

    private init() {}

    // MARK: - Device Listing

    /// 모든 연결된 기기 목록 (시뮬레이터 + 실기기)
    private func listAllDevices() async throws -> [DeviceInfo] {
        var devices: [DeviceInfo] = []

        // 시뮬레이터 목록
        let simulators = try simctlRunner.listDevices()
        devices.append(contentsOf: simulators)

        // 실기기 목록 (devicectl)
        let physicalDeviceList = try listPhysicalDevices()
        devices.append(contentsOf: physicalDeviceList)

        return devices
    }

    /// 실기기만 조회 (devicectl 사용)
    private func listPhysicalDevices() throws -> [DeviceInfo] {
        let deviceCtlDevices = try deviceCtlRunner.listDevices()

        return deviceCtlDevices.map { info in
            DeviceInfo(
                id: info.hardwareUdid,
                name: info.name,
                type: .physical,
                isConnected: info.isConnected,
                osVersion: info.osVersion,
                model: info.model
            )
        }
    }

    // MARK: - Device Selection

    /// 기기 선택
    public func selectDevice(udid: String) async throws {
        // 기기가 존재하는지 확인
        let allDevices = try await listAllDevices()
        guard allDevices.contains(where: { $0.id == udid }) else {
            throw DeviceManagerError.deviceNotFound(udid)
        }

        currentDeviceId = udid
    }

    /// 기기 선택 해제 (자동 선택 모드로 전환)
    public func clearSelection() {
        currentDeviceId = nil
    }

    /// 현재 선택된 기기 정보
    public func getCurrentDevice() async throws -> DeviceInfo? {
        guard let udid = currentDeviceId else { return nil }

        let allDevices = try await listAllDevices()
        return allDevices.first { $0.id == udid }
    }

    /// 자동 기기 선택 (우선순위: 부팅된 시뮬레이터 > 연결된 실기기)
    private func autoSelectDevice() async throws -> DeviceInfo {
        let allDevices = try await listAllDevices()

        // 1. 부팅된 시뮬레이터 찾기
        if let bootedSimulator = allDevices.first(where: { $0.type == .simulator && $0.isConnected }) {
            currentDeviceId = bootedSimulator.id
            return bootedSimulator
        }

        // 2. 연결된 실기기 찾기
        if let physicalDevice = allDevices.first(where: { $0.type == .physical && $0.isConnected }) {
            currentDeviceId = physicalDevice.id
            return physicalDevice
        }

        // 3. 사용 가능한 시뮬레이터 찾기 (부팅되지 않은)
        if let availableSimulator = allDevices.first(where: { $0.type == .simulator }) {
            currentDeviceId = availableSimulator.id
            return availableSimulator
        }

        throw DeviceManagerError.noDeviceAvailable
    }

    // MARK: - Device Connection

    /// 실기기용 USB HTTP 클라이언트 생성
    private func getUSBHTTPClient(udid: String) throws -> USBHTTPClient {
        // devicectl로 기기 존재 여부 확인
        guard try deviceCtlRunner.findDevice(udid: udid) != nil else {
            throw DeviceManagerError.deviceNotFound(udid)
        }

        // USBHTTPClient가 내부적으로 usbmuxd를 통해 연결
        return USBHTTPClient(udid: udid, port: Self.agentPort)
    }

    /// 현재 선택된 기기에 맞는 AgentClient 반환
    private func getAgentClient() async throws -> any AgentClient {
        guard let device = try await getCurrentDevice() else {
            throw DeviceManagerError.noDeviceSelected
        }

        switch device.type {
        case .simulator:
            return IOSControlClient(port: Int(Self.agentPort))

        case .physical:
            return try getUSBHTTPClient(udid: device.id)
        }
    }

    /// 자동 기기 선택 후 AgentClient 반환
    /// 선택된 기기가 없으면 자동으로 선택합니다.
    public func getOrAutoSelectAgentClient() async throws -> any AgentClient {
        if currentDeviceId == nil {
            _ = try await autoSelectDevice()
        }
        return try await getAgentClient()
    }
}

// MARK: - Errors

public enum DeviceManagerError: Error, LocalizedError {
    case deviceNotFound(String)
    case noDeviceAvailable
    case noDeviceSelected
    case physicalDeviceNotYetSupported

    public var errorDescription: String? {
        switch self {
        case .deviceNotFound(let udid):
            return """
                Device not found: \(udid)

                Solutions:
                  1. Use list_devices to check currently connected devices
                  2. For physical devices, check USB connection status
                  3. For simulators, verify the simulator exists in Xcode
                """
        case .noDeviceAvailable:
            return """
                No iOS device or simulator available.

                Solutions:
                  - Simulator: Install Xcode, then run xcodebuild -downloadPlatform iOS
                  - Physical device: Connect via USB and select "Trust This Computer"
                """
        case .noDeviceSelected:
            return "No device selected. Use list_devices and select_device."
        case .physicalDeviceNotYetSupported:
            return "This feature is not yet supported on physical devices."
        }
    }
}
