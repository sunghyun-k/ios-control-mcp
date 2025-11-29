import Foundation

/// IOSControl 통합 오류 타입
public enum IOSControlError: Error, LocalizedError {
    // MARK: - 서버 관련
    case serverNotRunning
    case serverTimeout(TimeInterval)

    // MARK: - HTTP 관련
    case httpError(Int)
    case invalidResponse

    // MARK: - 요소 관련
    case elementNotFound(String)

    // MARK: - 시뮬레이터 관련
    case simulatorNotFound
    case simulatorBootFailed(udid: String, exitCode: Int)
    case simulatorBootTimeout(udid: String, timeout: TimeInterval)

    // MARK: - simctl 관련
    case simctlError(command: String, exitCode: Int32)
    case simctlAppNotFound
    case simctlInstallFailed(exitCode: Int)
    case simctlLaunchFailed(exitCode: Int)

    // MARK: - 인자 관련
    case missingArgument(String)
    case invalidArgumentType(key: String, expected: String)

    // MARK: - 도구 관련
    case unknownTool(String)

    public var errorDescription: String? {
        switch self {
        // 서버 관련
        case .serverNotRunning:
            return "SimulatorAgent 서버가 실행 중이지 않습니다"
        case .serverTimeout(let seconds):
            return "SimulatorAgent가 \(Int(seconds))초 내에 시작되지 않았습니다"

        // HTTP 관련
        case .httpError(let code):
            return "HTTP 오류: \(code)"
        case .invalidResponse:
            return "잘못된 응답"

        // 요소 관련
        case .elementNotFound(let label):
            return "요소를 찾을 수 없습니다: \(label)"

        // 시뮬레이터 관련
        case .simulatorNotFound:
            return "사용 가능한 iPhone 시뮬레이터가 없습니다"
        case .simulatorBootFailed(let udid, let code):
            return "시뮬레이터 부팅 실패: \(udid), 종료 코드: \(code)"
        case .simulatorBootTimeout(let udid, let timeout):
            return "시뮬레이터 \(udid)가 \(Int(timeout))초 내에 부팅되지 않았습니다"

        // simctl 관련
        case .simctlError(let command, let code):
            return "simctl \(command) 실패, 종료 코드: \(code)"
        case .simctlAppNotFound:
            return "SimulatorAgentTests-Runner.app을 찾을 수 없습니다. 'make agent'로 빌드하거나 IOS_CONTROL_AGENT_APP 환경변수를 설정하세요."
        case .simctlInstallFailed(let code):
            return "앱 설치 실패, 종료 코드: \(code)"
        case .simctlLaunchFailed(let code):
            return "앱 실행 실패, 종료 코드: \(code)"

        // 인자 관련
        case .missingArgument(let key):
            return "필수 인자 '\(key)'가 누락되었습니다"
        case .invalidArgumentType(let key, let expected):
            return "인자 '\(key)'의 타입이 잘못되었습니다. 예상: \(expected)"

        // 도구 관련
        case .unknownTool(let name):
            return "알 수 없는 도구: \(name)"
        }
    }
}
