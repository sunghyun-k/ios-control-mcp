import Foundation

/// 서버 설정 상수
enum Constants {
    /// HTTP 서버 기본 포트
    static let defaultPort: UInt16 = 22087
    /// HTTP 서버 IP 주소
    static let serverIP = "127.0.0.1"
    /// HTTP 서버 타임아웃 (초)
    static let serverTimeout: TimeInterval = 300

    /// 스프링보드 번들 ID
    static let springboardBundleId = "com.apple.springboard"

    /// 기본 탭 지속 시간
    static let defaultTapDuration: TimeInterval = 0.1
    /// 핀치 시작 거리
    static let pinchStartDistance: CGFloat = 100

    /// 기본 타이핑 빈도
    static let defaultTypingFrequency = 30
    /// 기본 JPEG 품질
    static let defaultJpegQuality = 0.8

    /// 포트 환경변수 키
    static let portEnvKey = "IOS_CONTROL_PORT"
    /// 시뮬레이터 UDID 환경변수 키
    static let simulatorUdidEnvKey = "SIMULATOR_UDID"
}
