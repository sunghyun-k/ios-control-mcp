import Foundation
import IOSControlClient

/// DeviceAgent 프로세스 관리
/// 실기기에 테스트를 설치하고 실행
actor DeviceAgentRunner {
    static let shared = DeviceAgentRunner()

    /// 실행 중인 xcodebuild 프로세스
    private var runningProcess: Process?

    /// 프로젝트 경로
    private let projectPath: String

    /// 빌드 디렉토리
    private let derivedDataPath: String

    init() {
        // MCP 서버 실행 위치 기준으로 프로젝트 경로 찾기
        let executablePath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let rootDir = executablePath
            .deletingLastPathComponent()  // MCPServer
            .deletingLastPathComponent()  // .build
            .deletingLastPathComponent()  // ios-control-mcp

        self.projectPath = rootDir.appendingPathComponent("SimulatorAgent/SimulatorAgent.xcodeproj").path
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

        // xcodebuild test-without-building 실행
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")

        var arguments = [
            "test-without-building",
            "-project", projectPath,
            "-scheme", "SimulatorAgent",
            "-destination", "id=\(udid)",
            "-derivedDataPath", derivedDataPath,
            "-only-testing:SimulatorAgentTests/SimulatorAgentTests/testRunServer",
            "CODE_SIGN_STYLE=Automatic"
        ]

        // TEAM ID가 환경변수로 제공되면 사용
        if let teamId = ProcessInfo.processInfo.environment["IOS_CONTROL_TEAM_ID"] {
            arguments.append("DEVELOPMENT_TEAM=\(teamId)")
        }

        process.arguments = arguments

        // stdout/stderr를 /dev/null로 리다이렉트 (노이즈 제거)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            runningProcess = process
        } catch {
            throw DeviceAgentError.launchFailed(error.localizedDescription)
        }

        // 서버 시작 대기
        try await waitForServer(udid: udid, timeout: timeout)
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
    case launchFailed(String)
    case processTerminated(Int32)
    case timeout(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let reason):
            return "Failed to launch device agent: \(reason)"
        case .processTerminated(let code):
            return "Device agent process terminated with code \(code)"
        case .timeout(let seconds):
            return "Device agent did not start within \(Int(seconds)) seconds"
        }
    }
}
