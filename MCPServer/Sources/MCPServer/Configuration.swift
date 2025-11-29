import Foundation

/// MCP 서버 설정
public struct Configuration: Sendable {
    /// 기본 설정
    public static let `default` = Configuration()

    // MARK: - AutomationServer

    /// AutomationServer HTTP 서버 호스트
    public let agentHost: String

    /// AutomationServer HTTP 서버 포트
    public let agentPort: Int

    /// AutomationServer 앱 이름
    public let agentAppName: String

    /// AutomationServer 번들 ID
    public let agentBundleId: String

    // MARK: - 타임아웃

    /// HTTP 요청 타임아웃 (초)
    public let httpTimeout: TimeInterval

    /// 서버 시작 대기 타임아웃 (초)
    public let serverStartTimeout: TimeInterval

    /// 시뮬레이터 부팅 대기 타임아웃 (초)
    public let simulatorBootTimeout: TimeInterval

    /// 짧은 상태 확인 타임아웃 (초)
    public let statusCheckTimeout: TimeInterval

    // MARK: - 환경변수 키

    /// Agent 앱 경로 환경변수 키
    public static let agentAppPathEnvKey = "IOS_CONTROL_AGENT_APP"

    // MARK: - 초기화

    public init(
        agentHost: String = "127.0.0.1",
        agentPort: Int = 22087,
        agentAppName: String = "AutomationServerTests-Runner.app",
        agentBundleId: String = "automationserver.AutomationServerTests.xctrunner",
        httpTimeout: TimeInterval = 30,
        serverStartTimeout: TimeInterval = 60,
        simulatorBootTimeout: TimeInterval = 60,
        statusCheckTimeout: TimeInterval = 1
    ) {
        self.agentHost = agentHost
        self.agentPort = agentPort
        self.agentAppName = agentAppName
        self.agentBundleId = agentBundleId
        self.httpTimeout = httpTimeout
        self.serverStartTimeout = serverStartTimeout
        self.simulatorBootTimeout = simulatorBootTimeout
        self.statusCheckTimeout = statusCheckTimeout
    }

    /// Agent 베이스 URL
    public var agentBaseURL: URL {
        URL(string: "http://\(agentHost):\(agentPort)")!
    }

    /// 상태 확인 URL
    public var statusURL: URL {
        agentBaseURL.appendingPathComponent("status")
    }
}
