import Common
import Foundation

/// iOS Automation 서버와 HTTP 통신만 담당하는 클라이언트
/// 비즈니스 로직은 iOSAutomation에서 처리
/// Transport를 주입받아 시뮬레이터/실기기 모두 지원
final class UIAutomationClient: Sendable {
    private let transport: any HTTPTransport

    /// 시뮬레이터용 기본 초기화 (URLSession 사용)
    init() {
        transport = URLSessionTransport()
    }

    /// Transport 주입 초기화 (시뮬레이터/실기기 선택 가능)
    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    // MARK: - GET 요청

    /// 서버 상태 확인
    func health() async throws -> Bool {
        let (_, statusCode) = try await transport.get("health")
        return statusCode == 200
    }

    /// 앱의 UI 스냅샷 가져오기
    func snapshot(bundleId: String) async throws -> AXSnapshot {
        let (data, statusCode) = try await transport.get("apps/\(bundleId)/snapshot")
        guard statusCode == 200 else {
            throw HTTPTransportError.httpError(statusCode: statusCode, body: data)
        }
        return try JSONDecoder().decode(AXSnapshot.self, from: data)
    }

    /// 화면 스크린샷 가져오기 (PNG 이미지 데이터)
    func screenshot() async throws -> Data {
        let (data, statusCode) = try await transport.get("screen/screenshot")
        guard statusCode == 200 else {
            throw HTTPTransportError.httpError(statusCode: statusCode, body: data)
        }
        return data
    }

    // MARK: - POST 요청

    /// 요소 탭
    func tap(bundleId: String, element: ElementTarget) async throws {
        let body = TapRequestBody(element: element)
        try await post(path: "apps/\(bundleId)/tap", body: body)
    }

    /// 좌표로 탭
    func tapAtPoint(x: Double, y: Double) async throws {
        let body = TapAtPointRequestBody(x: x, y: y)
        try await post(path: "screen/tapAtPoint", body: body)
    }

    /// 텍스트 입력
    func typeText(
        bundleId: String,
        text: String,
        element: ElementTarget? = nil,
        submit: Bool = false,
    ) async throws {
        let body = TypeTextRequestBody(text: text, element: element, submit: submit)
        try await post(path: "apps/\(bundleId)/typeText", body: body)
    }

    /// 드래그
    func drag(
        bundleId: String,
        source: ElementTarget,
        target: ElementTarget,
        pressDuration: Double = 0.5,
    ) async throws {
        let body = DragRequestBody(source: source, target: target, pressDuration: pressDuration)
        try await post(path: "apps/\(bundleId)/drag", body: body)
    }

    /// 스와이프
    func swipe(
        bundleId: String,
        direction: SwipeDirection,
        element: ElementTarget? = nil,
    ) async throws {
        let body = SwipeRequestBody(direction: direction, element: element)
        try await post(path: "apps/\(bundleId)/swipe", body: body)
    }

    /// 앱 실행
    func launchApp(bundleId: String) async throws {
        try await post(path: "apps/\(bundleId)/launch")
    }

    /// 하드웨어 버튼 누르기
    func pressButton(_ button: HardwareButton) async throws {
        let body = PressButtonRequestBody(button: button)
        try await post(path: "device/button", body: body)
    }

    /// 핀치 줌
    func pinch(
        bundleId: String,
        scale: Double,
        velocity: Double = 100,
        element: ElementTarget? = nil,
    ) async throws {
        let body = PinchRequestBody(scale: scale, velocity: velocity, element: element)
        try await post(path: "apps/\(bundleId)/pinch", body: body)
    }

    // MARK: - Private

    /// POST 요청 헬퍼 (body 없음)
    private func post(path: String) async throws {
        let (_, statusCode) = try await transport.post(path, body: nil)
        guard statusCode == 200 else {
            throw HTTPTransportError.httpError(statusCode: statusCode, body: nil)
        }
    }

    /// POST 요청 헬퍼 (body 있음)
    private func post(path: String, body: some Encodable) async throws {
        let bodyData = try JSONEncoder().encode(body)
        let (_, statusCode) = try await transport.post(path, body: bodyData)
        guard statusCode == 200 else {
            throw HTTPTransportError.httpError(statusCode: statusCode, body: nil)
        }
    }
}
