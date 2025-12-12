import Common
import FlyingFox
import Foundation
import XCTest

/// 텍스트 입력 핸들러
/// POST /apps/:bundleId/typeText
struct TypeTextHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }

        guard let app = XCUIApplication.app(bundleId: bundleId) else {
            return .notFound("App not found")
        }

        do {
            let body = try await JSONDecoder().decode(
                TypeTextRequestBody.self,
                from: request.bodyData,
            )

            app.activate()

            // 요소 쿼리: element 지정시 해당 타입, 아니면 searchFields + textFields 둘 다
            let queries: [XCUIElementQuery] = if let elementTarget = body.element {
                [app.query(for: elementTarget.elementType)]
            } else {
                [app.searchFields, app.textFields]
            }

            // selector로 찾거나, 없으면 첫 번째 요소 (여러 쿼리 중 첫 번째로 존재하는 요소)
            var foundElement: XCUIElement?
            for query in queries {
                let element: XCUIElement = if let selector = body.element?.selector {
                    app.findElement(in: query, selector: selector)
                } else {
                    query.firstMatch
                }
                if element.waitForExistence(timeout: 2) {
                    foundElement = element
                    break
                }
            }

            guard let element = foundElement else {
                return .notFound("Element not found")
            }

            element.tap()
            element.typeText(body.text)

            if body.submit {
                app.typeText("\r")
            }

            return .ok()
        } catch {
            return .badRequest("Invalid request: \(error)")
        }
    }
}
