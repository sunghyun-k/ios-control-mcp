import Foundation

/// 기기 관리자
/// 시뮬레이터와 실제 iOS 기기를 통합 관리합니다.
public actor DeviceManager {
    /// 싱글톤 인스턴스
    public static let shared = DeviceManager()

    /// 에이전트 포트 번호
    public static let agentPort: UInt16 = 22087

    /// 실기기 포트 범위 (LookinServer 방식)
    public static let physicalDevicePortStart: UInt16 = 47175
    public static let physicalDevicePortEnd: UInt16 = 47179

    private let simctlRunner = SimctlRunner.shared
    private let deviceCtlRunner = DeviceCtlRunner.shared
    private let usbMuxClient = USBMuxClient()

    private var currentDeviceId: String?
    private var isListeningUSB = false
    private var physicalDevices: [String: USBMuxDeviceInfo] = [:]  // UDID -> Info
    private var deviceCtlCache: [String: DeviceCtlDeviceInfo] = [:]  // UDID -> DeviceCtl Info

    private init() {}

    // MARK: - Device Listing

    /// 모든 연결된 기기 목록 (시뮬레이터 + 실기기)
    public func listAllDevices() async throws -> [DeviceInfo] {
        var devices: [DeviceInfo] = []

        // 시뮬레이터 목록
        let simulators = try simctlRunner.listDevices()
        devices.append(contentsOf: simulators)

        // 실기기 목록 (USB 리스닝 자동 시작)
        let physicalDeviceList = try await listPhysicalDevices()
        devices.append(contentsOf: physicalDeviceList)

        return devices
    }

    /// 시뮬레이터만 조회
    public func listSimulators() throws -> [DeviceInfo] {
        try simctlRunner.listDevices()
    }

    /// 실기기만 조회
    public func listPhysicalDevices() async throws -> [DeviceInfo] {
        // devicectl로 실기기 정보 조회 및 캐시 갱신
        try await refreshDeviceCtlCache()

        // USB 리스닝이 시작되지 않았으면 시작하고 기기 이벤트 수신 대기
        if !isListeningUSB {
            try await startUSBListening()
            // 기기 연결 이벤트 수신 대기 (최대 500ms)
            try await Task.sleep(for: .milliseconds(500))
        }

        // 현재 캐시된 기기 목록에 devicectl 정보 병합
        return physicalDevices.values.map { usbInfo in
            let udid = usbInfo.serialNumber

            // devicectl 캐시에서 추가 정보 조회
            if let deviceCtlInfo = deviceCtlCache[udid] {
                return DeviceInfo(
                    id: udid,
                    name: deviceCtlInfo.name,
                    type: .physical,
                    isConnected: deviceCtlInfo.isConnected,
                    osVersion: deviceCtlInfo.osVersion,
                    model: deviceCtlInfo.model
                )
            } else {
                // devicectl 정보가 없는 경우 기본값
                return DeviceInfo(
                    id: udid,
                    name: "iOS Device",
                    type: .physical,
                    isConnected: true,
                    osVersion: nil,
                    model: nil
                )
            }
        }
    }

    /// devicectl 캐시 갱신
    private func refreshDeviceCtlCache() async throws {
        // devicectl은 동기 명령이므로 백그라운드에서 실행
        let devices = try await Task.detached {
            try DeviceCtlRunner.shared.listDevices()
        }.value

        // UDID 기반으로 캐시 갱신
        deviceCtlCache.removeAll()
        for device in devices {
            deviceCtlCache[device.hardwareUdid] = device
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

    /// 현재 선택된 기기 ID
    public func getCurrentDeviceId() -> String? {
        currentDeviceId
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
    public func autoSelectDevice() async throws -> DeviceInfo {
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

    // MARK: - USB Listening

    /// USB 기기 연결 이벤트 수신 시작
    public func startUSBListening() async throws {
        guard !isListeningUSB else { return }

        isListeningUSB = true
        let events = try await usbMuxClient.startListening()

        Task { [weak self] in
            for await event in events {
                await self?.handleUSBEvent(event)
            }
        }
    }

    /// USB 기기 연결 이벤트 수신 중지
    public func stopUSBListening() async {
        isListeningUSB = false
        await usbMuxClient.stopListening()
    }

    private func handleUSBEvent(_ event: USBMuxDeviceEvent) {
        switch event {
        case .attached(let info):
            physicalDevices[info.serialNumber] = info

        case .detached(let info):
            physicalDevices.removeValue(forKey: info.serialNumber)

            // 현재 선택된 기기가 분리되면 선택 해제
            if currentDeviceId == info.serialNumber {
                currentDeviceId = nil
            }
        }
    }

    // MARK: - Device Connection

    /// 현재 선택된 기기에 연결할 URL 반환
    public func getAgentURL() async throws -> URL {
        guard let device = try await getCurrentDevice() else {
            throw DeviceManagerError.noDeviceSelected
        }

        switch device.type {
        case .simulator:
            // 시뮬레이터는 직접 로컬호스트 연결
            return URL(string: "http://127.0.0.1:\(Self.agentPort)")!

        case .physical:
            // 실기기는 usbmuxd를 통한 연결
            // TODO: USB 포트 포워딩 구현
            throw DeviceManagerError.physicalDeviceNotYetSupported
        }
    }

    /// 실기기의 Agent 포트에 연결된 파일 디스크립터 반환
    public func connectToPhysicalDevice(udid: String) throws -> Int32 {
        guard let info = physicalDevices[udid] else {
            throw DeviceManagerError.deviceNotFound(udid)
        }

        return try usbMuxClient.connectToDevice(
            deviceID: info.deviceID,
            port: Self.agentPort
        )
    }

    /// 실기기용 USB HTTP 클라이언트 생성
    public func getUSBHTTPClient(udid: String) throws -> USBHTTPClient {
        guard let info = physicalDevices[udid] else {
            throw DeviceManagerError.deviceNotFound(udid)
        }

        return USBHTTPClient(deviceID: info.deviceID, port: Self.agentPort)
    }

    /// 현재 선택된 기기에 맞는 AgentClient 반환
    public func getAgentClient() async throws -> any AgentClient {
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

    /// 캐시된 실기기 정보 조회 (디버깅용)
    public func getPhysicalDeviceInfo(udid: String) -> USBMuxDeviceInfo? {
        physicalDevices[udid]
    }

    // MARK: - Command Runners

    /// 현재 선택된 기기의 명령 러너 반환
    public func getCommandRunner() async throws -> any DeviceCommandRunner {
        guard let device = try await getCurrentDevice() else {
            throw DeviceManagerError.noDeviceSelected
        }

        switch device.type {
        case .simulator:
            return simctlRunner

        case .physical:
            // TODO: 실기기용 CommandRunner 구현
            throw DeviceManagerError.physicalDeviceNotYetSupported
        }
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
                기기를 찾을 수 없습니다: \(udid)

                해결 방법:
                  1. list_devices로 현재 연결된 기기 목록 확인
                  2. 실기기인 경우 USB 연결 상태 확인
                  3. 시뮬레이터인 경우 Xcode에서 해당 시뮬레이터가 존재하는지 확인
                """
        case .noDeviceAvailable:
            return """
                사용 가능한 iOS 기기 또는 시뮬레이터가 없습니다.

                해결 방법:
                  - 시뮬레이터: Xcode 설치 후 xcodebuild -downloadPlatform iOS 실행
                  - 실기기: USB로 Mac에 연결하고 "이 컴퓨터를 신뢰" 선택
                """
        case .noDeviceSelected:
            return "기기가 선택되지 않았습니다. list_devices와 select_device를 사용하세요."
        case .physicalDeviceNotYetSupported:
            return "이 기능은 아직 실기기에서 지원되지 않습니다."
        }
    }
}
