import Common
import XCTest

extension XCUIApplication {
    /// bundleId로 앱을 가져오고 존재 여부 확인
    static func app(bundleId: String) -> XCUIApplication? {
        let app = XCUIApplication(bundleIdentifier: bundleId)
        return app.exists ? app : nil
    }

    /// elementType에 맞는 쿼리 생성
    func query(for elementType: AXElementType?) -> XCUIElementQuery {
        if let axType = elementType,
           let xcuiType = XCUIElement.ElementType(rawValue: UInt(axType.rawValue))
        {
            return descendants(matching: xcuiType)
        }
        return descendants(matching: .any)
    }

    /// selector로 요소 찾기
    /// - selector가 nil이면 query의 첫 번째 요소 반환
    func findElement(in query: XCUIElementQuery, selector: ElementSelector?) -> XCUIElement {
        guard let selector else {
            return query.firstMatch
        }
        switch selector {
        case .label(let label):
            return query[label].firstMatch
        case .identifier(let id):
            return query.matching(identifier: id).firstMatch
        }
    }
}
