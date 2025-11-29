import Foundation
import IOSControlClient

/// DeviceAgent 프로세스 관리
/// xctestrun 파일이 없으면 자동으로 빌드 후 실행
actor DeviceAgentRunner {
    static let shared = DeviceAgentRunner()

    /// 실행 중인 xcodebuild 프로세스
    private var runningProcess: Process?

    /// 프로젝트 루트 디렉토리
    private let rootDir: URL

    /// 빌드 디렉토리 (xctestrun 파일 위치)
    private let derivedDataPath: String

    /// Xcode 프로젝트 경로
    private let xcodeProjectPath: String

    /// 환경변수 키
    static let xctestrunPathEnvKey = "IOS_CONTROL_DEVICE_XCTESTRUN"
    static let teamIdEnvKey = "IOS_CONTROL_TEAM_ID"
    static let projectPathEnvKey = "IOS_CONTROL_PROJECT_PATH"

    init() {
        // 실행 파일 위치
        let executablePath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let executableDir = executablePath.deletingLastPathComponent()

        self.rootDir = executableDir
        self.derivedDataPath = executableDir.appendingPathComponent(".build/DeviceAgent").path
        self.xcodeProjectPath = executableDir.appendingPathComponent("SimulatorAgent/SimulatorAgent.xcodeproj").path
    }

    /// Xcode 프로젝트 경로 찾기
    /// 환경변수 IOS_CONTROL_PROJECT_PATH가 있으면 사용, 없으면 실행파일과 같은 디렉토리에서 찾음
    private func findXcodeProject() -> String? {
        let fm = FileManager.default

        // 1. 환경변수
        if let envPath = ProcessInfo.processInfo.environment[Self.projectPathEnvKey] {
            let url = URL(fileURLWithPath: envPath)
            if fm.fileExists(atPath: url.path) {
                return url.path
            }
            return nil
        }

        // 2. 실행파일과 같은 디렉토리
        if fm.fileExists(atPath: xcodeProjectPath) {
            return xcodeProjectPath
        }

        return nil
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

        // xctestrun 파일 찾기, 없으면 빌드
        var xctestrunPath = findXctestrun()
        if xctestrunPath == nil {
            // 빌드 시도
            try await buildAgent()
            xctestrunPath = findXctestrun()
        }

        guard let xctestrunPath else {
            throw DeviceAgentError.buildFailed("xctestrun file not found after build")
        }

        // 테스트 실행 (test-without-building -xctestrun)
        try await runTest(udid: udid, xctestrunPath: xctestrunPath)

        // 서버 시작 대기
        try await waitForServer(udid: udid, timeout: timeout)
    }

    /// TEAM ID 가져오기 (환경변수)
    private func getTeamId() -> String? {
        ProcessInfo.processInfo.environment[Self.teamIdEnvKey]
    }

    /// Agent 빌드 (build-for-testing)
    private func buildAgent() async throws {
        guard let teamId = getTeamId() else {
            throw DeviceAgentError.teamIdRequired
        }

        // Xcode 프로젝트 찾기
        guard let projectPath = findXcodeProject() else {
            throw DeviceAgentError.xcodeProjectNotFound(xcodeProjectPath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = [
            "build-for-testing",
            "-project", projectPath,
            "-scheme", "SimulatorAgent",
            "-destination", "generic/platform=iOS",
            "-derivedDataPath", derivedDataPath,
            "DEVELOPMENT_TEAM=\(teamId)",
            "CODE_SIGN_STYLE=Automatic"
        ]

        // 빌드 출력을 stderr로 전달 (MCP 프로토콜은 stdout 사용)
        process.standardOutput = FileHandle.standardError
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                throw DeviceAgentError.buildFailed("xcodebuild exited with code \(process.terminationStatus)")
            }
        } catch let error as DeviceAgentError {
            throw error
        } catch {
            throw DeviceAgentError.buildFailed(error.localizedDescription)
        }
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
    case teamIdRequired
    case xcodeProjectNotFound(String)
    case buildFailed(String)
    case launchFailed(String)
    case processTerminated(Int32)
    case timeout(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .teamIdRequired:
            return """
                Physical device requires Apple Developer Team ID.
                Set the IOS_CONTROL_TEAM_ID environment variable.

                Example (MCP config):
                  "env": { "IOS_CONTROL_TEAM_ID": "YOUR_TEAM_ID" }

                Find your Team ID:
                  security find-identity -v -p codesigning | head -1
                """
        case .xcodeProjectNotFound(let path):
            return "Xcode project not found at: \(path)"
        case .buildFailed(let reason):
            return "Failed to build device agent: \(reason)"
        case .launchFailed(let reason):
            return "Failed to launch device agent: \(reason)"
        case .processTerminated(let code):
            return "Device agent process terminated with code \(code)"
        case .timeout(let seconds):
            return "Device agent did not start within \(Int(seconds)) seconds"
        }
    }
}
