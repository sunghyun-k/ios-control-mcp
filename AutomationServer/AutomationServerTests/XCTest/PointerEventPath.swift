import Foundation

struct PointerEventPath {

    static func pathForTouch(at point: CGPoint, offset: TimeInterval = 0) -> Self {
        let alloced = ObjCBridge.allocInstance("XCPointerEventPath")!
        let selector = NSSelectorFromString("initForTouchAtPoint:offset:")
        let imp = alloced.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, CGPoint, TimeInterval) -> NSObject
        let method = unsafeBitCast(imp, to: Method.self)
        let path = method(alloced, selector, point, offset)
        return Self(path: path, offset: offset)
    }

    let path: NSObject
    var offset: TimeInterval

    private init(path: NSObject, offset: TimeInterval) {
        self.path = path
        self.offset = offset
    }

    mutating func liftUp() {
        let selector = NSSelectorFromString("liftUpAtOffset:")
        let imp = path.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, TimeInterval) -> ()
        let method = unsafeBitCast(imp, to: Method.self)
        method(path, selector, offset)
    }

    mutating func moveTo(point: CGPoint) {
        let selector = NSSelectorFromString("moveToPoint:atOffset:")
        let imp = path.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, CGPoint, TimeInterval) -> ()
        let method = unsafeBitCast(imp, to: Method.self)
        method(path, selector, point, offset)
    }

    mutating func set(modifiers: KeyModifierFlags = []) {
        let selector = NSSelectorFromString("setModifiers:mergeWithCurrentModifierFlags:atOffset:")
        let imp = path.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, UInt64, Bool, TimeInterval) -> ()
        let method = unsafeBitCast(imp, to: Method.self)
        method(path, selector, modifiers.rawValue, false, offset)
    }
}
