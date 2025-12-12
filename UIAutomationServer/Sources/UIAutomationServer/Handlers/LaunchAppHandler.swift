import FlyingFox
import Foundation
import XCTest

/// 앱 실행 핸들러
/// POST /apps/:bundleId/launch
struct LaunchAppHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }

        let app = XCUIApplication(bundleIdentifier: bundleId)
        app.launch()

        return .ok()
    }
}
