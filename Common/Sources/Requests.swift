import Foundation

/// 요소 선택자: label 또는 identifier
public enum ElementSelector: Codable, Sendable {
    case label(String)
    case identifier(String)
}

/// 요소를 찾기 위한 공통 타입
/// - elementType만 지정: 해당 타입의 첫 번째 요소
/// - selector만 지정: label 또는 identifier로 찾기
/// - 둘 다 지정: 해당 타입 중 selector로 찾기
public struct ElementTarget: Codable, Sendable {
    public let elementType: AXElementType?
    public let selector: ElementSelector?

    public init(
        elementType: AXElementType? = nil,
        selector: ElementSelector? = nil,
    ) {
        self.elementType = elementType
        self.selector = selector
    }
}

// MARK: - Request Bodies (bundleId는 경로 파라미터로 전달)

/// Tap 요청 바디
public struct TapRequestBody: Codable, Sendable {
    public let element: ElementTarget

    public init(element: ElementTarget) {
        self.element = element
    }
}

/// Long Press 요청 바디
public struct LongPressRequestBody: Codable, Sendable {
    public let element: ElementTarget
    /// 누르고 있는 시간 (초)
    public let duration: Double

    public init(element: ElementTarget, duration: Double = 1.0) {
        self.element = element
        self.duration = duration
    }
}

/// 텍스트 입력 요청 바디
public struct TypeTextRequestBody: Codable, Sendable {
    public let text: String
    public let element: ElementTarget?
    public let submit: Bool

    public init(
        text: String,
        element: ElementTarget? = nil,
        submit: Bool = false,
    ) {
        self.text = text
        self.element = element
        self.submit = submit
    }
}

/// 드래그 요청 바디
public struct DragRequestBody: Codable, Sendable {
    public let source: ElementTarget
    public let target: ElementTarget
    public let pressDuration: Double

    public init(
        source: ElementTarget,
        target: ElementTarget,
        pressDuration: Double = 0.5,
    ) {
        self.source = source
        self.target = target
        self.pressDuration = pressDuration
    }
}

/// 스와이프 방향
public enum SwipeDirection: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

/// 스와이프 요청 바디
public struct SwipeRequestBody: Codable, Sendable {
    public let direction: SwipeDirection
    public let element: ElementTarget?

    public init(
        direction: SwipeDirection,
        element: ElementTarget? = nil,
    ) {
        self.direction = direction
        self.element = element
    }
}

/// 하드웨어 버튼 종류
public enum HardwareButton: String, Codable, Sendable {
    case home
    case volumeUp
    case volumeDown
}

/// 버튼 누르기 요청 바디
public struct PressButtonRequestBody: Codable, Sendable {
    public let button: HardwareButton

    public init(button: HardwareButton) {
        self.button = button
    }
}

/// 좌표 탭 요청 바디
public struct TapAtPointRequestBody: Codable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// 핀치 요청 바디
public struct PinchRequestBody: Codable, Sendable {
    /// 핀치 스케일 (1.0 미만: 줌아웃, 1.0 초과: 줌인)
    public let scale: Double
    /// 핀치 속도 (초 단위)
    public let velocity: Double
    /// 핀치할 요소 (nil이면 앱 전체)
    public let element: ElementTarget?

    public init(
        scale: Double,
        velocity: Double = 1.0,
        element: ElementTarget? = nil,
    ) {
        self.scale = scale
        self.velocity = velocity
        self.element = element
    }
}
