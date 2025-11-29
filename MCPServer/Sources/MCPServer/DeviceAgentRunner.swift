import Foundation
import IOSControlClient

/// DeviceAgent 프로세스 관리
/// 미리 빌드된 xctestrun 파일을 사용하여 실기기에서 테스트 실행
actor DeviceAgentRunner {
    static let shared = DeviceAgentRunner()

    /// 실행 중인 xcodebuild 프로세스
    private var runningProcess: Process?

    /// 빌드 디렉토리 (xctestrun 파일 위치)
    private let derivedDataPath: String

    /// 환경변수 키
    static let xctestrunPathEnvKey = "IOS_CONTROL_DEVICE_XCTESTRUN"

    init() {
        // MCP 서버 실행 위치 기준으로 빌드 디렉토리 찾기
        let executablePath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let rootDir = executablePath
            .deletingLastPathComponent()  // MCPServer
            .deletingLastPathComponent()  // .build
            .deletingLastPathComponent()  // ios-control-mcp

        self.derivedDataPath = rootDir.appendingPathComponent(".build/DeviceAgent").path
    }

    // MARK: - Public

    /// 실기기에서 Agent 시작
    func start(udid: String, timeout: TimeInterval = 60) async throws {
        // 이미 실행 중인지 확인
        if await isRunning(udid: udid) {
            return
        }

        // 기존 프로세스 정리
        stop()

        // xctestrun 파일 찾기
        guard let xctestrunPath = findXctestrun() else {
            throw DeviceAgentError.xctestrunNotFound
        }

        // 테스트 실행 (test-without-building -xctestrun)
        try await runTest(udid: udid, xctestrunPath: xctestrunPath)

        // 서버 시작 대기
        try await waitForServer(udid: udid, timeout: timeout)
    }

    /// xctestrun 파일 찾기
    private func findXctestrun() -> String? {
        let fm = FileManager.default

        // 1. 환경변수
        if let envPath = ProcessInfo.processInfo.environment[Self.xctestrunPathEnvKey] {
            if fm.fileExists(atPath: envPath) {
                return envPath
            }
        }

        // 2. 실행파일과 같은 디렉토리
        let executablePath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let executableDir = executablePath.deletingLastPathComponent()

        if let files = try? fm.contentsOfDirectory(atPath: executableDir.path) {
            if let xctestrun = files.first(where: { $0.hasSuffix(".xctestrun") }) {
                return executableDir.appendingPathComponent(xctestrun).path
            }
        }

        // 3. derivedData/Build/Products 에서 찾기
        let productsPath = "\(derivedDataPath)/Build/Products"
        if let files = try? fm.contentsOfDirectory(atPath: productsPath) {
            if let xctestrun = files.first(where: { $0.hasSuffix(".xctestrun") }) {
                return "\(productsPath)/\(xctestrun)"
            }
        }

        return nil
    }

    /// 테스트 실행 (test-without-building -xctestrun)
    private func runTest(udid: String, xctestrunPath: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")

        let arguments = [
            "test-without-building",
            "-xctestrun", xctestrunPath,
            "-destination", "id=\(udid)",
            "-only-testing:SimulatorAgentTests/SimulatorAgentTests/testRunServer"
        ]

        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            runningProcess = process
        } catch {
            throw DeviceAgentError.launchFailed(error.localizedDescription)
        }
    }

    /// Agent 중지
    func stop() {
        runningProcess?.terminate()
        runningProcess = nil
    }

    /// 서버가 실행 중인지 확인
    func isRunning(udid: String) async -> Bool {
        do {
            let client = try await DeviceManager.shared.getUSBHTTPClient(udid: udid)
            _ = try await client.status()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private

    /// 서버 시작 대기
    private func waitForServer(udid: String, timeout: TimeInterval) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            // 프로세스가 종료되었는지 확인
            if let process = runningProcess, !process.isRunning {
                throw DeviceAgentError.processTerminated(process.terminationStatus)
            }

            // 서버 응답 확인
            if await isRunning(udid: udid) {
                return
            }

            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        }

        // 타임아웃
        stop()
        throw DeviceAgentError.timeout(timeout)
    }
}

// MARK: - Errors

enum DeviceAgentError: Error, LocalizedError {
    case xctestrunNotFound
    case launchFailed(String)
    case processTerminated(Int32)
    case timeout(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .xctestrunNotFound:
            return "Device agent not found. Run 'make device-agent TEAM=<YOUR_TEAM_ID>' first."
        case .launchFailed(let reason):
            return "Failed to launch device agent: \(reason)"
        case .processTerminated(let code):
            return "Device agent process terminated with code \(code)"
        case .timeout(let seconds):
            return "Device agent did not start within \(Int(seconds)) seconds"
        }
    }
}
