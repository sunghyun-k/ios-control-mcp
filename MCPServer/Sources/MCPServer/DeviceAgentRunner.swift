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
        self.xcodeProjectPath = executableDir.appendingPathComponent("AutomationServer/AutomationServer.xcodeproj").path
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
        // USB 연결 여부 먼저 확인 (빠른 실패)
        guard await checkUSBConnection(udid: udid) else {
            throw DeviceAgentError.usbNotConnected(udid)
        }

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
            "-scheme", "AutomationServer",
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
            "-only-testing:AutomationServerTests/AutomationServerTests/testRunServer"
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
        let client = USBHTTPClient(udid: udid)
        return await client.isServerRunning()
    }

    /// USB 연결 여부 확인 (usbmuxd를 통해)
    private func checkUSBConnection(udid: String) async -> Bool {
        let client = USBMuxClient()
        do {
            let events = try await client.startListening()

            let searchTask = Task<Bool, Never> {
                for await event in events {
                    if case .attached(let info) = event {
                        if info.serialNumber == udid {
                            return true
                        }
                    }
                }
                return false
            }

            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 500_000_000)  // 0.5초
                searchTask.cancel()
            }

            let result = await searchTask.value
            timeoutTask.cancel()
            await client.stopListening()
            return result
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
    case usbNotConnected(String)
    case teamIdRequired
    case xcodeProjectNotFound(String)
    case buildFailed(String)
    case launchFailed(String)
    case processTerminated(Int32)
    case timeout(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .usbNotConnected(let udid):
            return """
                기기가 USB로 연결되어 있지 않습니다: \(udid)

                실기기를 제어하려면 USB 케이블로 Mac에 연결해야 합니다.
                Wi-Fi 연결만으로는 Agent와 통신할 수 없습니다.

                해결 방법:
                  1. USB 케이블로 기기를 Mac에 연결
                  2. "이 컴퓨터를 신뢰하시겠습니까?" 팝업에서 "신뢰" 선택
                  3. list_devices로 연결 상태 확인
                """
        case .teamIdRequired:
            return """
                실기기 사용에는 Apple Developer Team ID가 필요합니다.

                1. Team ID 찾기:
                   security find-identity -v -p codesigning
                   → 괄호 안의 10자리 문자열이 Team ID입니다

                2. MCP 설정에 추가:
                   "env": { "IOS_CONTROL_TEAM_ID": "YOUR_TEAM_ID" }

                Team ID가 없다면 Xcode에서 본인 Apple ID로 로그인 후
                아무 앱이나 기기에 빌드하면 자동으로 생성됩니다.
                """
        case .xcodeProjectNotFound(let path):
            return """
                Xcode 프로젝트를 찾을 수 없습니다: \(path)

                Xcode가 설치되어 있는지 확인하세요.
                """
        case .buildFailed(let reason):
            return """
                실기기용 Agent 빌드 실패: \(reason)

                해결 방법:
                  1. Team ID가 올바른지 확인
                  2. 기기가 USB로 연결되어 있는지 확인
                  3. Xcode에서 해당 기기로 아무 앱이나 한 번 빌드하여 프로비저닝 설정
                  4. Xcode → Settings → Accounts에서 Apple ID 로그인 확인
                """
        case .launchFailed(let reason):
            return """
                실기기에서 Agent 실행 실패: \(reason)

                해결 방법:
                  1. 기기가 USB로 연결되어 있는지 확인
                  2. 기기가 잠금 해제되어 있는지 확인
                  3. 개발자 모드가 활성화되어 있는지 확인 (설정 → 개인정보 보호 및 보안)
                """
        case .processTerminated(let code):
            return """
                Agent 프로세스가 종료되었습니다 (코드: \(code))

                해결 방법:
                  1. 기기 화면이 잠겨있지 않은지 확인
                  2. "신뢰하지 않는 개발자" 경고가 있는지 확인
                     → 설정 → 일반 → VPN 및 기기 관리에서 앱 신뢰
                  3. 기기를 재부팅 후 재시도
                """
        case .timeout(let seconds):
            return """
                Agent가 \(Int(seconds))초 내에 시작되지 않았습니다.

                해결 방법:
                  1. 기기 화면이 잠겨있지 않은지 확인
                  2. "신뢰하지 않는 개발자" 경고가 있는지 확인
                     → 설정 → 일반 → VPN 및 기기 관리에서 앱 신뢰
                  3. USB 케이블을 재연결 후 재시도
                """
        }
    }
}
