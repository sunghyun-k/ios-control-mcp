import FlyingFox
import Foundation
import os

enum Route: String, CaseIterable {
    case status
    case tap
    case swipe
    case inputText
    case tree
    case screenshot
    case foregroundApp

    var httpRoute: HTTPRoute {
        HTTPRoute(rawValue)
    }
}

struct IOSControlServer {
    private let port: UInt16
    private let logger = Logger(subsystem: "ios-control", category: "HTTPServer")

    init(port: UInt16 = 22087) {
        if let envPort = ProcessInfo.processInfo.environment["IOS_CONTROL_PORT"],
           let p = UInt16(envPort) {
            self.port = p
        } else {
            self.port = port
        }
    }

    func start() async throws {
        let server = HTTPServer(
            address: try .inet(ip4: "127.0.0.1", port: port),
            timeout: 300
        )

        await server.appendRoute(Route.status.httpRoute, to: StatusHandler())
        await server.appendRoute(Route.tap.httpRoute, to: TapHandler())
        await server.appendRoute(Route.swipe.httpRoute, to: SwipeHandler())
        await server.appendRoute(Route.inputText.httpRoute, to: InputTextHandler())
        await server.appendRoute(Route.tree.httpRoute, to: TreeHandler())
        await server.appendRoute(Route.screenshot.httpRoute, to: ScreenshotHandler())
        await server.appendRoute(Route.foregroundApp.httpRoute, to: ForegroundAppHandler())

        logger.info("IOSControl HTTP server started on port \(port)")
        try await server.run()
    }
}
