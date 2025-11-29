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
            return """
                AutomationServer가 실행 중이지 않습니다.

                해결 방법:
                  1. 기기/시뮬레이터가 켜져 있는지 확인
                  2. 다시 시도하면 자동으로 Agent가 시작됩니다
                  3. 문제가 지속되면 기기를 재부팅하세요
                """
        case .serverTimeout(let seconds):
            return """
                AutomationServer가 \(Int(seconds))초 내에 시작되지 않았습니다.

                해결 방법:
                  1. 기기/시뮬레이터 화면이 잠겨있지 않은지 확인
                  2. 실기기의 경우 "신뢰하지 않는 개발자" 경고가 있는지 확인
                     → 설정 → 일반 → VPN 및 기기 관리에서 앱 신뢰
                  3. 기기를 재부팅 후 재시도
                """

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
            return """
                사용 가능한 iPhone 시뮬레이터가 없습니다.

                해결 방법:
                  1. Xcode가 설치되어 있는지 확인
                  2. iOS 시뮬레이터 런타임 다운로드: xcodebuild -downloadPlatform iOS
                  3. Xcode → Settings → Platforms에서 iOS 시뮬레이터 확인
                """
        case .simulatorBootFailed(let udid, let code):
            return """
                시뮬레이터 부팅 실패: \(udid), 종료 코드: \(code)

                해결 방법:
                  1. Xcode → Settings → Platforms에서 iOS 런타임 설치 확인
                  2. 시뮬레이터 앱에서 해당 기기 삭제 후 재생성
                  3. xcrun simctl erase \(udid) 로 시뮬레이터 초기화
                """
        case .simulatorBootTimeout(let udid, let timeout):
            return """
                시뮬레이터 \(udid)가 \(Int(timeout))초 내에 부팅되지 않았습니다.

                해결 방법:
                  1. 시뮬레이터 앱을 직접 열어 부팅 상태 확인
                  2. Mac 재시작 후 재시도
                  3. 다른 시뮬레이터로 시도
                """

        // simctl 관련
        case .simctlError(let command, let code):
            return "simctl \(command) 실패, 종료 코드: \(code)"
        case .simctlAppNotFound:
            return """
                AutomationServer 앱을 찾을 수 없습니다.

                처음 실행 시 자동으로 빌드됩니다.
                Xcode가 설치되어 있는지 확인하세요.
                """
        case .simctlInstallFailed(let code):
            return """
                앱 설치 실패, 종료 코드: \(code)

                해결 방법:
                  1. 시뮬레이터가 부팅되어 있는지 확인
                  2. 시뮬레이터를 재부팅 후 재시도
                """
        case .simctlLaunchFailed(let code):
            return """
                앱 실행 실패, 종료 코드: \(code)

                해결 방법:
                  1. 시뮬레이터에서 앱이 설치되어 있는지 확인
                  2. 시뮬레이터를 재부팅 후 재시도
                """

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
