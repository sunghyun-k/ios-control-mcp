import Common
import FlyingFox
import os
import XCTest

final class Entry: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testRunServer() async throws {
        let server = HTTPServer(address: .inet(port: 22087))

        // Health check
        await server.appendRoute("GET /health", to: HealthHandler())

        // App 관련 라우트 (경로 파라미터 사용)
        await server.appendRoute("GET /apps/:bundleId/snapshot", to: SnapshotHandler())
        await server.appendRoute("POST /apps/:bundleId/launch", to: LaunchAppHandler())
        await server.appendRoute("POST /apps/:bundleId/tap", to: TapHandler())
        await server.appendRoute("POST /apps/:bundleId/typeText", to: TypeTextHandler())
        await server.appendRoute("POST /apps/:bundleId/drag", to: DragHandler())
        await server.appendRoute("POST /apps/:bundleId/swipe", to: SwipeHandler())
        await server.appendRoute("POST /apps/:bundleId/pinch", to: PinchHandler())

        // Device 관련 라우트
        await server.appendRoute("POST /device/button", to: PressButtonHandler())

        // Screen 관련 라우트
        await server.appendRoute("GET /screen/screenshot", to: ScreenshotHandler())
        await server.appendRoute("POST /screen/tapAtPoint", to: TapAtPointHandler())

        logger.info("🚀 서버 시작: http://localhost:22087")
        try await server.run()
    }
}

private let logger = Logger(subsystem: "ios-control", category: "Entry")
