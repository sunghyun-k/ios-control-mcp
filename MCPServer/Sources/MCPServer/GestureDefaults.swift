import Foundation

/// 제스처 관련 기본값
enum GestureDefaults {
    /// swipe 기본 지속 시간 (초)
    static let swipeDuration: Double = 0.5

    /// scroll 기본 지속 시간 (초)
    static let scrollDuration: Double = 0.3

    /// drag 기본 이동 시간 (초)
    static let dragDuration: Double = 0.3

    /// drag 기본 홀드 시간 (초)
    static let holdDuration: Double = 0.5

    /// scroll 기본 거리 (픽셀)
    static let scrollDistance: Double = 300

    /// swipe 끝 지점에서 손을 때기 전 대기 시간 (초)
    static let liftDelay: Double = 0.1
}
