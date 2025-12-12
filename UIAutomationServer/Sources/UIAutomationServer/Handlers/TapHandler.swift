import Common
import FlyingFox
import Foundation
import XCTest

/// 탭 액션 핸들러
/// POST /apps/:bundleId/tap
struct TapHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }

        guard let app = XCUIApplication.app(bundleId: bundleId) else {
            return .notFound("App not found")
        }

        do {
            let body = try await JSONDecoder().decode(TapRequestBody.self, from: request.bodyData)

            let query = app.query(for: body.element.elementType)
            let element = app.findElement(in: query, selector: body.element.selector)

            guard element.waitForExistence(timeout: 5) else {
                return .notFound("Element not found")
            }

            guard element.isHittable else {
                return .badRequest("Element not hittable: \(element.debugDescription)")
            }

            element.tap()
            return .ok()
        } catch {
            return .badRequest("Invalid request: \(error)")
        }
    }
}
