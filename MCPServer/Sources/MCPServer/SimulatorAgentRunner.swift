import Foundation
import Common
import IOSControlClient

/// SimulatorAgent 프로세스 관리
/// 빌드된 .app을 시뮬레이터에 설치하고 실행
actor SimulatorAgentRunner {
    static let shared = SimulatorAgentRunner()

    private let config: Configuration
    private let simctl: SimctlRunner

    /// 현재 사용 중인 시뮬레이터 ID
    private var currentDeviceId: String?

    init(config: Configuration = .default) {
        self.config = config
        self.simctl = SimctlRunner()
    }

    // MARK: - Simulator Device Info

    private struct SimulatorDevice {
        let udid: String
        let name: String
        let state: String
        let deviceTypeIdentifier: String
        let isAvailable: Bool
    }

    private struct SimulatorRuntime {
        let identifier: String
        let version: (major: Int, minor: Int)
        let devices: [SimulatorDevice]
    }

    // MARK: - Public

    /// 서버 시작 (이미 실행 중이면 무시)
    func start(deviceId: String? = nil, timeout: TimeInterval? = nil) async throws {
        let serverTimeout = timeout ?? config.serverStartTimeout

        // 이미 실행 중인지 확인 (실제 서버 응답 기준)
        if await isRunning() {
            return
        }

        // app 경로 찾기
        guard let appPath = findAgentApp() else {
            throw IOSControlError.simctlAppNotFound
        }

        // 시뮬레이터 선택 및 부팅
        let targetDeviceId = try await ensureSimulatorBooted(preferredDeviceId: deviceId)
        self.currentDeviceId = targetDeviceId

        // 앱 설치
        try simctl.installApp(deviceId: targetDeviceId, appPath: appPath.path)

        // 앱 실행
        try simctl.launchApp(deviceId: targetDeviceId, bundleId: config.agentBundleId)

        // 서버 시작 대기
        try await waitForServer(timeout: serverTimeout)
    }

    /// 서버 중지
    func stop() {
        guard let deviceId = currentDeviceId else { return }
        simctl.terminateApp(deviceId: deviceId, bundleId: config.agentBundleId)
    }

    /// 서버가 실행 중인지 확인 (실제 HTTP 응답 기준)
    func isRunning() async -> Bool {
        do {
            let urlConfig = URLSessionConfiguration.default
            urlConfig.timeoutIntervalForRequest = config.statusCheckTimeout
            let session = URLSession(configuration: urlConfig)
            let (_, response) = try await session.data(from: config.statusURL)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // 연결 실패 = 서버 미실행
        }
        return false
    }

    // MARK: - App Path Resolution

    /// SimulatorAgent.app 경로 찾기
    /// 환경변수 IOS_CONTROL_AGENT_APP이 있으면 사용, 없으면 실행파일과 같은 디렉토리에서 찾음
    private func findAgentApp() -> URL? {
        let fm = FileManager.default

        // 1. 환경변수
        if let envPath = ProcessInfo.processInfo.environment[Configuration.agentAppPathEnvKey] {
            let url = URL(fileURLWithPath: envPath)
            if fm.fileExists(atPath: url.path) {
                return url
            }
            return nil
        }

        // 2. 실행파일과 같은 디렉토리
        let executablePath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let executableDir = executablePath.deletingLastPathComponent()
        let appPath = executableDir.appendingPathComponent(config.agentAppName)
        if fm.fileExists(atPath: appPath.path) {
            return appPath
        }

        return nil
    }

    // MARK: - Simulator

    /// 시뮬레이터 부팅 보장 (이미 부팅되어 있으면 해당 ID 반환, 없으면 최적의 시뮬레이터 선택 후 부팅)
    private func ensureSimulatorBooted(preferredDeviceId: String?) async throws -> String {
        // 1. 이미 부팅된 시뮬레이터가 있으면 사용
        let bootedSimulators = simctl.getBootedSimulators()
        if let bootedId = bootedSimulators.first {
            return bootedId
        }

        // 2. 선호하는 device ID가 있으면 해당 시뮬레이터 부팅
        if let deviceId = preferredDeviceId {
            try simctl.bootSimulator(deviceId: deviceId)
            try await waitForSimulatorBoot(deviceId: deviceId)
            return deviceId
        }

        // 3. 최적의 시뮬레이터 선택 (가장 높은 iOS 버전의 iPhone)
        guard let bestDevice = findBestIPhoneSimulator() else {
            throw IOSControlError.simulatorNotFound
        }

        // 4. 선택된 시뮬레이터 부팅
        try simctl.bootSimulator(deviceId: bestDevice.udid)
        try await waitForSimulatorBoot(deviceId: bestDevice.udid)

        return bestDevice.udid
    }

    /// 가장 높은 iOS 버전의 iPhone 시뮬레이터 찾기
    private func findBestIPhoneSimulator() -> SimulatorDevice? {
        let runtimes = listSimulatorRuntimes()

        // iOS 런타임만 필터링하고 버전 내림차순 정렬
        let sortedRuntimes = runtimes
            .filter { $0.identifier.contains("iOS") }
            .sorted { $0.version.major != $1.version.major
                ? $0.version.major > $1.version.major
                : $0.version.minor > $1.version.minor
            }

        // 가장 높은 버전부터 순회하며 사용 가능한 iPhone 찾기
        for runtime in sortedRuntimes {
            let iPhones = runtime.devices.filter {
                $0.isAvailable && $0.deviceTypeIdentifier.contains("iPhone")
            }
            if let firstIPhone = iPhones.first {
                return firstIPhone
            }
        }

        return nil
    }

    /// 시뮬레이터 런타임 및 디바이스 목록 조회
    private func listSimulatorRuntimes() -> [SimulatorRuntime] {
        do {
            let data = try simctl.listDevicesJSON()
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let devices = json["devices"] as? [String: [[String: Any]]] else {
                return []
            }

            var runtimes: [SimulatorRuntime] = []

            for (runtimeId, deviceList) in devices {
                // 버전 파싱: com.apple.CoreSimulator.SimRuntime.iOS-18-6 -> (18, 6)
                guard let version = parseIOSVersion(from: runtimeId) else { continue }

                let simulatorDevices = deviceList.compactMap { dict -> SimulatorDevice? in
                    guard let udid = dict["udid"] as? String,
                          let name = dict["name"] as? String,
                          let state = dict["state"] as? String,
                          let deviceType = dict["deviceTypeIdentifier"] as? String,
                          let isAvailable = dict["isAvailable"] as? Bool else {
                        return nil
                    }
                    return SimulatorDevice(
                        udid: udid,
                        name: name,
                        state: state,
                        deviceTypeIdentifier: deviceType,
                        isAvailable: isAvailable
                    )
                }

                runtimes.append(SimulatorRuntime(
                    identifier: runtimeId,
                    version: version,
                    devices: simulatorDevices
                ))
            }

            return runtimes
        } catch {
            return []
        }
    }

    /// 런타임 식별자에서 iOS 버전 파싱
    private func parseIOSVersion(from runtimeId: String) -> (major: Int, minor: Int)? {
        // com.apple.CoreSimulator.SimRuntime.iOS-18-6 -> iOS-18-6
        guard let iosRange = runtimeId.range(of: "iOS-") else { return nil }
        let versionString = String(runtimeId[iosRange.upperBound...])

        // 18-6 -> [18, 6]
        let parts = versionString.split(separator: "-").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }

        return (major: parts[0], minor: parts[1])
    }

    /// 시뮬레이터 부팅 완료 대기
    private func waitForSimulatorBoot(deviceId: String) async throws {
        let timeout = config.simulatorBootTimeout
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let bootedSimulators = simctl.getBootedSimulators()
            if bootedSimulators.contains(deviceId) {
                // 부팅 완료 후 약간의 안정화 시간
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
                return
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        }

        throw IOSControlError.simulatorBootTimeout(udid: deviceId, timeout: timeout)
    }

    // MARK: - Server Wait

    /// 서버 시작 대기
    private func waitForServer(timeout: TimeInterval) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            do {
                let (_, response) = try await URLSession.shared.data(from: config.statusURL)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    return
                }
            } catch {
                // 아직 시작되지 않음
            }

            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        }

        // 타임아웃
        stop()
        throw IOSControlError.serverTimeout(timeout)
    }
}
