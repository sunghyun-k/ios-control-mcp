import Foundation

/// 기기 관리자
/// 시뮬레이터와 실제 iOS 기기를 통합 관리합니다.
public final class DeviceManager: @unchecked Sendable {
    private let simControlClient = SimulatorControlClient()
    private let deviceControlClient = DeviceControlClient()

    private var currentDeviceId: String?

    public init() {}

    // MARK: - Device Listing

    /// 모든 연결된 기기 목록 (시뮬레이터 + 실기기)
    public func listAllDevices() throws -> [DeviceInfo] {
        var devices: [DeviceInfo] = []

        // 시뮬레이터 목록 (부팅된 것만)
        let simulators = try simControlClient.allSimulators().filter(\.isBooted)
        devices.append(contentsOf: simulators.map { sim in
            DeviceInfo(
                id: sim.udid,
                name: sim.name,
                type: .simulator,
                isConnected: true,
                osVersion: sim.iosVersion,
                model: nil,
            )
        })

        // 실기기 목록 (devicectl)
        let physicalDevices = try listPhysicalDevices()
        devices.append(contentsOf: physicalDevices)

        return devices
    }

    /// 실기기만 조회 (devicectl 사용)
    private func listPhysicalDevices() throws -> [DeviceInfo] {
        let deviceCtlDevices = try deviceControlClient.listDevices()

        return deviceCtlDevices.compactMap { device in
            guard let udid = device.hardwareUdid else { return nil }
            return DeviceInfo(
                id: udid,
                name: device.name,
                type: .physical,
                isConnected: device.isConnected && device.isWired,
                osVersion: device.osVersion,
                model: device.model,
            )
        }
    }

    // MARK: - Device Selection

    /// 기기 선택
    public func selectDevice(udid: String) throws {
        // 기기가 존재하는지 확인
        let allDevices = try listAllDevices()
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
    public func getCurrentDevice() throws -> DeviceInfo? {
        guard let udid = currentDeviceId else { return nil }

        let allDevices = try listAllDevices()
        return allDevices.first { $0.id == udid }
    }

    /// 자동 기기 선택
    /// 우선순위: USB 연결된 실기기 > 부팅된 시뮬레이터 > 사용 가능한 시뮬레이터
    public func autoSelectDevice() throws -> DeviceInfo {
        let allDevices = try listAllDevices()

        // 1. USB로 연결된 실기기 찾기
        if let physicalDevice = allDevices
            .first(where: { $0.type == .physical && $0.isConnected })
        {
            currentDeviceId = physicalDevice.id
            return physicalDevice
        }

        // 2. 부팅된 시뮬레이터 찾기
        if let bootedSimulator = allDevices
            .first(where: { $0.type == .simulator && $0.isConnected })
        {
            currentDeviceId = bootedSimulator.id
            return bootedSimulator
        }

        // 3. 사용 가능한 시뮬레이터 찾기 (부팅 시도)
        let allSims = try simControlClient.allSimulators()
        if let availableSimulator = allSims.first(where: { $0.isAvailable }) {
            try simControlClient.boot(simulatorId: availableSimulator.udid)
            currentDeviceId = availableSimulator.udid
            return DeviceInfo(
                id: availableSimulator.udid,
                name: availableSimulator.name,
                type: .simulator,
                isConnected: true,
                osVersion: availableSimulator.iosVersion,
                model: nil,
            )
        }

        throw DeviceManagerError.noDeviceAvailable
    }

    /// 자동 기기 선택 후 Transport 반환
    /// 선택된 기기가 없으면 자동으로 선택합니다.
    public func getOrAutoSelectTransport() throws -> any HTTPTransport {
        if currentDeviceId == nil {
            _ = try autoSelectDevice()
        }
        return try getTransport()
    }

    /// 현재 선택된 기기에 맞는 Transport 반환
    public func getTransport() throws -> any HTTPTransport {
        guard let device = try getCurrentDevice() else {
            throw DeviceManagerError.noDeviceSelected
        }

        switch device.type {
        case .simulator:
            return URLSessionTransport()
        case .physical:
            return USBMuxTransport(udid: device.id)
        }
    }
}

// MARK: - Errors

public enum DeviceManagerError: Error, LocalizedError {
    case deviceNotFound(String)
    case noDeviceAvailable
    case noDeviceSelected

    public var errorDescription: String? {
        switch self {
        case .deviceNotFound(let udid):
            """
            Device not found: \(udid)

            Solutions:
              1. Use list_devices to check currently connected devices
              2. For physical devices, check USB connection status
              3. For simulators, verify the simulator exists in Xcode
            """
        case .noDeviceAvailable:
            """
            No iOS device or simulator available.

            Solutions:
              - Simulator: Install Xcode, then run xcodebuild -downloadPlatform iOS
              - Physical device: Connect via USB and select "Trust This Computer"
            """
        case .noDeviceSelected:
            "No device selected. Use list_devices and select_device."
        }
    }
}
