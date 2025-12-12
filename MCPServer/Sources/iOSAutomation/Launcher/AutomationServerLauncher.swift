import Foundation

/// UIAutomationServer 실행기
/// 시뮬레이터와 실기기 모두 지원
public final class AutomationServerLauncher: @unchecked Sendable {
    private let xcodeBuildClient = XcodeBuildClient()

    /// 워크스페이스 경로
    private let workspacePath: String

    /// 스킴 이름
    private let scheme = "UIAutomationServer"

    /// 서버 포트
    private let serverPort: UInt16 = 22087

    /// 서버 시작 타임아웃
    private let serverStartTimeout: TimeInterval

    /// 실행 중인 xcodebuild 프로세스
    private var runningProcess: Process?

    /// 현재 실행 중인 디바이스 정보
    private var currentDevice: DeviceInfo?

    public init(workspacePath: String, serverStartTimeout: TimeInterval = 60) {
        self.workspacePath = workspacePath
        self.serverStartTimeout = serverStartTimeout
    }

    // MARK: - 서버 시작/중지

    /// 서버 시작
    /// - Parameter device: 대상 디바이스
    public func start(device: DeviceInfo) async throws {
        // 이미 같은 디바이스에서 실행 중이면 스킵
        if let current = currentDevice, current.id == device.id {
            if await isRunning(device: device) {
                return
            }
        }

        // 기존 프로세스 정리
        stop()

        // 실기기인 경우 USB 연결 확인
        if device.type == .physical {
            guard checkUSBConnection(udid: device.id) else {
                throw AutomationServerError.usbNotConnected(device.id)
            }
        }

        // 빌드
        let buildResult = try await build(device: device)

        // 실행
        runningProcess = try xcodeBuildClient.testWithoutBuilding(
            xctestrunPath: buildResult.xctestrunPath,
            deviceId: device.id,
        )
        currentDevice = device

        // 서버 시작 대기
        try await waitForServer(device: device)
    }

    /// 서버 중지
    public func stop() {
        runningProcess?.terminate()
        runningProcess = nil
        currentDevice = nil
    }

    // MARK: - 상태 확인

    /// 서버가 실행 중인지 확인
    public func isRunning(device: DeviceInfo) async -> Bool {
        switch device.type {
        case .simulator:
            await checkSimulatorServer()
        case .physical:
            await checkPhysicalServer(udid: device.id)
        }
    }

    // MARK: - Private - 빌드

    /// 디바이스에 맞게 빌드
    private func build(device: DeviceInfo) async throws -> XcodeBuildClient.BuildResult {
        switch device.type {
        case .simulator:
            try await xcodeBuildClient.buildForTesting(
                target: .workspace(path: workspacePath),
                scheme: scheme,
                deviceId: device.id,
            )
        case .physical:
            try await buildForPhysicalDevice(udid: device.id)
        }
    }

    /// 실기기용 빌드 (Team ID 필요)
    private func buildForPhysicalDevice(udid: String) async throws -> XcodeBuildClient.BuildResult {
        guard let teamId = ProcessInfo.processInfo.environment[iOSAutomationEnv.teamId] else {
            throw AutomationServerError.teamIdRequired
        }

        return try await xcodeBuildClient.buildForTesting(
            target: .workspace(path: workspacePath),
            scheme: scheme,
            deviceId: udid,
            teamId: teamId,
        )
    }

    // MARK: - Private - 서버 확인

    /// 시뮬레이터 서버 확인 (localhost HTTP)
    private func checkSimulatorServer() async -> Bool {
        let url = URL(string: "http://localhost:\(serverPort)/health")!
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 2
            let session = URLSession(configuration: config)
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // 연결 실패 = 서버 미실행
        }
        return false
    }

    /// 실기기 서버 확인 (USBMux)
    private func checkPhysicalServer(udid: String) async -> Bool {
        let transport = USBMuxTransport(udid: udid, port: serverPort)
        do {
            let (_, statusCode) = try await transport.get("health")
            return statusCode == 200
        } catch {
            return false
        }
    }

    /// USB 연결 여부 확인
    private func checkUSBConnection(udid: String) -> Bool {
        let client = USBMuxClient()
        do {
            let devices = try client.listConnectedDevices(timeout: 0.5)
            return devices.contains { $0.serialNumber == udid }
        } catch {
            return false
        }
    }

    /// 서버 시작 대기
    private func waitForServer(device: DeviceInfo) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < serverStartTimeout {
            // 프로세스가 종료되었는지 확인
            if let process = runningProcess, !process.isRunning {
                throw AutomationServerError.processTerminated(process.terminationStatus)
            }

            // 서버 응답 확인
            if await isRunning(device: device) {
                return
            }

            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        }

        // 타임아웃
        stop()
        throw AutomationServerError.timeout(serverStartTimeout)
    }
}

// MARK: - Errors

public enum AutomationServerError: Error, LocalizedError {
    case teamIdRequired
    case usbNotConnected(String)
    case processTerminated(Int32)
    case timeout(TimeInterval)

    public var errorDescription: String? {
        switch self {
        case .teamIdRequired:
            """
            Physical device requires Apple Developer Team ID.

            1. Find your Team ID:
               security find-identity -v -p codesigning
               → 10-character string in parentheses is Team ID

            2. Add to MCP config:
               "env": { "IOS_CONTROL_TEAM_ID": "YOUR_TEAM_ID" }

            If no Team ID exists, sign in to Xcode with Apple ID
            and build any app to device to auto-generate one.
            """
        case .usbNotConnected(let udid):
            """
            Device not connected via USB: \(udid)

            Physical devices require USB connection for Agent communication.
            Wi-Fi connection alone is not sufficient.

            Solutions:
              1. Connect device via USB cable
              2. Select "Trust This Computer" on device
              3. Verify connection with list_devices
            """
        case .processTerminated(let code):
            """
            Server process terminated (code: \(code))

            Solutions:
              1. Ensure device screen is unlocked
              2. Check for "Untrusted Developer" warning
                 → Settings → General → VPN & Device Management → Trust app
              3. Restart device and retry
            """
        case .timeout(let seconds):
            """
            Server did not start within \(Int(seconds)) seconds.

            Solutions:
              1. Ensure device screen is unlocked
              2. Check for "Untrusted Developer" warning
                 → Settings → General → VPN & Device Management → Trust app
              3. Reconnect USB cable and retry
            """
        }
    }
}
