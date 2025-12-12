import Common
import FlyingFox
import Foundation
import XCTest

/// 핀치 줌 핸들러
/// POST /apps/:bundleId/pinch
struct PinchHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }

        guard let app = XCUIApplication.app(bundleId: bundleId) else {
            return .notFound("App not found")
        }

        do {
            let body = try await JSONDecoder().decode(PinchRequestBody.self, from: request.bodyData)

            // 핀치할 요소 결정 (지정된 요소 또는 앱 전체)
            let targetElement: XCUIElement
            if let element = body.element {
                let query = app.query(for: element.elementType)
                targetElement = app.findElement(in: query, selector: element.selector)

                guard targetElement.waitForExistence(timeout: 5) else {
                    return .notFound("Element not found")
                }
            } else {
                targetElement = app
            }

            // 핀치 수행
            targetElement.pinch(withScale: body.scale, velocity: body.velocity)

            return .ok()
        } catch {
            return .badRequest("Invalid request: \(error)")
        }
    }
}
