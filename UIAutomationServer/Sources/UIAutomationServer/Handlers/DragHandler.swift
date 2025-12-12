import Common
import FlyingFox
import Foundation
import XCTest

/// 드래그 액션 핸들러
/// POST /apps/:bundleId/drag
struct DragHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }

        guard let app = XCUIApplication.app(bundleId: bundleId) else {
            return .notFound("App not found")
        }

        do {
            let body = try await JSONDecoder().decode(DragRequestBody.self, from: request.bodyData)

            // 소스 요소 찾기
            let sourceQuery = app.query(for: body.source.elementType)
            let sourceElement = app.findElement(in: sourceQuery, selector: body.source.selector)

            guard sourceElement.waitForExistence(timeout: 5) else {
                return .notFound("Source element not found")
            }

            // 타겟 요소 찾기
            let targetQuery = app.query(for: body.target.elementType)
            let targetElement = app.findElement(in: targetQuery, selector: body.target.selector)

            guard targetElement.waitForExistence(timeout: 5) else {
                return .notFound("Target element not found")
            }

            // 드래그 수행
            sourceElement.press(forDuration: body.pressDuration, thenDragTo: targetElement)
            return .ok()
        } catch {
            return .badRequest("Invalid request: \(error)")
        }
    }
}
