import Foundation

/// Objective-C 런타임 브릿지
/// XCTest 프라이빗 API 접근을 위한 유틸리티
enum ObjCBridge {
    /// 클래스를 찾아서 인스턴스를 할당합니다.
    static func allocInstance(_ className: String) -> NSObject? {
        guard let clazz = objc_lookUpClass(className) else { return nil }
        return clazz.alloc() as? NSObject
    }

    /// 클래스 메서드를 호출합니다 (반환 타입: NSObject).
    static func invokeClassMethod(_ className: String, selector selectorName: String) -> NSObject? {
        guard let clazz: AnyClass = NSClassFromString(className) else { return nil }
        let selector = NSSelectorFromString(selectorName)
        guard let imp = class_getMethodImplementation(object_getClass(clazz), selector) else { return nil }

        typealias Method = @convention(c) (AnyClass, Selector) -> NSObject
        let method = unsafeBitCast(imp, to: Method.self)
        return method(clazz, selector)
    }
}
