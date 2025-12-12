import FlyingFox
import Foundation
import XCTest

/// 앱 스크린샷 핸들러
/// GET /apps/:bundleId/screenshot
struct ScreenshotHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let pngData = XCUIScreen.main.screenshot().pngRepresentation
        return .png(pngData)
    }
}
