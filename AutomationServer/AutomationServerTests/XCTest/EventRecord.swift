import Foundation
import UIKit

@objc
final class EventRecord: NSObject {
    let eventRecord: NSObject

    enum Style: String {
        case singeFinger = "Single-Finger Touch Action"
        case multiFinger = "Multi-Finger Touch Action"
    }

    init(orientation: UIInterfaceOrientation, style: Style = .singeFinger) {
        let alloced = ObjCBridge.allocInstance("XCSynthesizedEventRecord")!
        eventRecord = alloced
            .perform(
                NSSelectorFromString("initWithName:interfaceOrientation:"),
                with: style.rawValue,
                with: orientation
            )
            .takeUnretainedValue() as! NSObject
    }

    func addPointerTouchEvent(at point: CGPoint, touchUpAfter: TimeInterval?) -> Self {
        var path = PointerEventPath.pathForTouch(at: point)
        path.offset += touchUpAfter ?? Constants.defaultTapDuration
        path.liftUp()
        return add(path)
    }

    func addSwipeEvent(start: CGPoint, end: CGPoint, duration: TimeInterval, holdDuration: TimeInterval? = nil, liftDelay: TimeInterval? = nil) -> Self {
        var path = PointerEventPath.pathForTouch(at: start)
        path.offset += holdDuration ?? Constants.defaultTapDuration
        path.moveTo(point: end)
        path.offset += duration
        if let liftDelay = liftDelay {
            path.offset += liftDelay
        }
        path.liftUp()
        return add(path)
    }

    func addPinchEvent(center: CGPoint, scale: Double, velocity: Double) -> Self {
        let duration = abs(1.0 - scale) / velocity
        let startDistance = Constants.pinchStartDistance
        let endDistance = startDistance * scale

        let finger1Start = CGPoint(x: center.x - startDistance / 2, y: center.y)
        let finger1End = CGPoint(x: center.x - endDistance / 2, y: center.y)
        let finger2Start = CGPoint(x: center.x + startDistance / 2, y: center.y)
        let finger2End = CGPoint(x: center.x + endDistance / 2, y: center.y)

        var path1 = PointerEventPath.pathForTouch(at: finger1Start)
        path1.offset += Constants.defaultTapDuration
        path1.moveTo(point: finger1End)
        path1.offset += duration
        path1.liftUp()

        var path2 = PointerEventPath.pathForTouch(at: finger2Start)
        path2.offset += Constants.defaultTapDuration
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
