import Foundation
import UIKit

@objc
final class EventRecord: NSObject {
    let eventRecord: NSObject
    static let defaultTapDuration = 0.1

    enum Style: String {
        case singeFinger = "Single-Finger Touch Action"
        case multiFinger = "Multi-Finger Touch Action"
    }

    init(orientation: UIInterfaceOrientation, style: Style = .singeFinger) {
        eventRecord = objc_lookUpClass("XCSynthesizedEventRecord")?.alloc()
            .perform(
                NSSelectorFromString("initWithName:interfaceOrientation:"),
                with: style.rawValue,
                with: orientation
            )
            .takeUnretainedValue() as! NSObject
    }

    func addPointerTouchEvent(at point: CGPoint, touchUpAfter: TimeInterval?) -> Self {
        var path = PointerEventPath.pathForTouch(at: point)
        path.offset += touchUpAfter ?? Self.defaultTapDuration
        path.liftUp()
        return add(path)
    }

    func addSwipeEvent(start: CGPoint, end: CGPoint, duration: TimeInterval) -> Self {
        var path = PointerEventPath.pathForTouch(at: start)
        path.offset += Self.defaultTapDuration
        path.moveTo(point: end)
        path.offset += duration
        path.liftUp()
        return add(path)
    }

    /// 핀치 제스처 추가
    /// - Parameters:
    ///   - center: 핀치 중심점
    ///   - scale: 1.0 미만이면 줌 아웃, 1.0 초과면 줌 인
    ///   - velocity: 핀치 속도 (1.0이 기본)
    func addPinchEvent(center: CGPoint, scale: Double, velocity: Double) -> Self {
        let duration = abs(1.0 - scale) / velocity
        let startDistance: CGFloat = 100
        let endDistance = startDistance * scale

        // 두 손가락의 시작/끝 위치 계산
        let finger1Start = CGPoint(x: center.x - startDistance / 2, y: center.y)
        let finger1End = CGPoint(x: center.x - endDistance / 2, y: center.y)
        let finger2Start = CGPoint(x: center.x + startDistance / 2, y: center.y)
        let finger2End = CGPoint(x: center.x + endDistance / 2, y: center.y)

        // 첫 번째 손가락
        var path1 = PointerEventPath.pathForTouch(at: finger1Start)
        path1.offset += Self.defaultTapDuration
        path1.moveTo(point: finger1End)
        path1.offset += duration
        path1.liftUp()

        // 두 번째 손가락
        var path2 = PointerEventPath.pathForTouch(at: finger2Start)
        path2.offset += Self.defaultTapDuration
        path2.moveTo(point: finger2End)
        path2.offset += duration
        path2.liftUp()

        return add(path1).add(path2)
    }

    func add(_ path: PointerEventPath) -> Self {
        let selector = NSSelectorFromString("addPointerEventPath:")
        let imp = eventRecord.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, NSObject) -> ()
        let method = unsafeBitCast(imp, to: Method.self)
        method(eventRecord, selector, path.path)
        return self
    }
}
