import Foundation
import Common

/// IOSControl HTTP 클라이언트 (시뮬레이터용)
public final class IOSControlClient: AgentClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let simctl: SimctlRunner

    public init(host: String = "127.0.0.1", port: Int = 22087, httpTimeout: TimeInterval = 30) {
        self.baseURL = URL(string: "http://\(host):\(port)")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = httpTimeout
        self.session = URLSession(configuration: config)
        self.simctl = SimctlRunner()
    }

    // MARK: - Private

    private func request(_ method: String, _ endpoint: String, body: Data? = nil) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IOSControlError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            throw IOSControlError.httpError(httpResponse.statusCode)
        }

        return data
    }

    private func post<T: Encodable>(_ endpoint: String, body: T) async throws -> Data {
        let bodyData = try JSONEncoder().encode(body)
        return try await request("POST", endpoint, body: bodyData)
    }

    private func get(_ endpoint: String) async throws -> Data {
        try await request("GET", endpoint)
    }

    // MARK: - Public API

    /// 서버 상태 확인
    public func status() async throws -> StatusResponse {
        let data = try await get("status")
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }

    /// 탭
    public func tap(_ request: TapRequest) async throws {
        _ = try await post("tap", body: request)
    }

    /// 탭 (좌표 직접 지정)
    public func tap(x: Double, y: Double, duration: TimeInterval? = nil) async throws {
        try await tap(TapRequest(x: x, y: y, duration: duration))
    }

    /// 스와이프
    public func swipe(_ request: SwipeRequest) async throws {
        _ = try await post("swipe", body: request)
    }

    /// 스와이프 (좌표 직접 지정)
    public func swipe(startX: Double, startY: Double, endX: Double, endY: Double, duration: TimeInterval = 0.5, holdDuration: TimeInterval? = nil, liftDelay: TimeInterval? = nil) async throws {
        try await swipe(SwipeRequest(startX: startX, startY: startY, endX: endX, endY: endY, duration: duration, holdDuration: holdDuration, liftDelay: liftDelay))
    }

    /// 텍스트 입력
    public func inputText(_ request: InputTextRequest) async throws {
        _ = try await post("inputText", body: request)
    }

    /// 텍스트 입력 (문자열 직접 지정)
    public func inputText(_ text: String) async throws {
        try await inputText(InputTextRequest(text: text))
    }

    /// UI 트리 조회
    public func tree(appBundleId: String? = nil) async throws -> TreeResponse {
        let data = try await post("tree", body: TreeRequest(appBundleId: appBundleId))
        return try JSONDecoder().decode(TreeResponse.self, from: data)
    }

    /// 포그라운드 앱 조회
    public func foregroundApp() async throws -> ForegroundAppResponse {
        let data = try await get("foregroundApp")
        return try JSONDecoder().decode(ForegroundAppResponse.self, from: data)
    }

    /// 설치된 앱 목록 조회 (simctl 사용, Agent에서 UDID 가져옴)
    public func listApps() async throws -> ListAppsResponse {
        let udid = try await getSimulatorUDID()
        let apps = try simctl.listApps(deviceId: udid)
        let bundleIds = apps.compactMap { $0["CFBundleIdentifier"] as? String }.sorted()
        return ListAppsResponse(bundleIds: bundleIds)
    }

    /// 앱 실행
    public func launchApp(bundleId: String) async throws {
        _ = try await post("launchApp", body: LaunchAppRequest(bundleId: bundleId))
    }

    /// 홈으로 이동
    public func goHome() async throws {
        _ = try await get("goHome")
    }

    /// 스크린샷
    public func screenshot(format: String = "png") async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent("screenshot"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "format", value: format)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw IOSControlError.invalidResponse
        }

        return data
    }

    /// 서버가 실행 중인지 확인
    public func isServerRunning() async -> Bool {
        do {
            _ = try await status()
            return true
        } catch {
            return false
        }
    }

    // MARK: - simctl 기반 API

    /// 시뮬레이터 UDID 가져오기 (내부 헬퍼)
    private func getSimulatorUDID() async throws -> String {
        let statusResponse = try await status()
        guard let udid = statusResponse.udid else {
            throw IOSControlError.invalidResponse
        }
        return udid
    }

    /// URL 열기
    public func openURL(_ url: String) async throws {
        let udid = try await getSimulatorUDID()
        try simctl.openURL(deviceId: udid, url: url)
    }

    /// 앱 종료
    public func terminateApp(bundleId: String) async throws {
        let udid = try await getSimulatorUDID()
        simctl.terminateApp(deviceId: udid, bundleId: bundleId)
    }

    /// 클립보드 내용 가져오기
    public func getPasteboard() async throws -> GetPasteboardResponse {
        let udid = try await getSimulatorUDID()
        let content = try simctl.getPasteboard(deviceId: udid)
        return GetPasteboardResponse(content: content.isEmpty ? nil : content)
    }

    /// 클립보드에 내용 설정
    public func setPasteboard(_ content: String) async throws {
        let udid = try await getSimulatorUDID()
        try simctl.setPasteboard(deviceId: udid, content: content)
    }

    /// 핀치 제스처
    public func pinch(_ request: PinchRequest) async throws {
        _ = try await post("pinch", body: request)
    }

    /// 핀치 제스처 (좌표 직접 지정)
    public func pinch(x: Double, y: Double, scale: Double, velocity: Double = 1.0) async throws {
        try await pinch(PinchRequest(x: x, y: y, scale: scale, velocity: velocity))
    }
}
