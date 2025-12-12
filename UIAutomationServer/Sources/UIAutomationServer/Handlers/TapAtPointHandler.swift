import Common
import FlyingFox
import Foundation
import XCTest

/// 좌표 탭 액션 핸들러
/// POST /screen/tapAtPoint
struct TapAtPointHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let body = try await JSONDecoder().decode(
                TapAtPointRequestBody.self,
                from: request.bodyData,
            )

            // Springboard 앱을 사용하여 화면 좌표로 탭
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let coordinate = springboard.coordinate(
                withNormalizedOffset: CGVector(dx: 0, dy: 0),
            ).withOffset(CGVector(dx: body.x, dy: body.y))

            coordinate.tap()
            return .ok()
        } catch {
            return .badRequest("Invalid request: \(error)")
        }
    }
}
