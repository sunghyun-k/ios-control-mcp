import FlyingFox
import Foundation
import os

/// 라우트 정의
enum Route: String, CaseIterable {
    case status
    case tap
    case swipe
    case inputText
    case tree
    case screenshot
    case foregroundApp
    case launchApp
    case goHome
    case pinch

    var route: String { rawValue }

    var handler: HTTPHandler {
        switch self {
        case .status: StatusHandler()
        case .tap: TapHandler()
        case .swipe: SwipeHandler()
        case .inputText: InputTextHandler()
        case .tree: TreeHandler()
        case .screenshot: ScreenshotHandler()
        case .foregroundApp: ForegroundAppHandler()
        case .launchApp: LaunchAppHandler()
        case .goHome: GoHomeHandler()
        case .pinch: PinchHandler()
        }
    }
}

struct IOSControlServer {
    private let port: UInt16
    private let logger = Logger(subsystem: "ios-control", category: "HTTPServer")

    init(port: UInt16 = Constants.defaultPort) {
        if let envPort = ProcessInfo.processInfo.environment[Constants.portEnvKey],
           let p = UInt16(envPort)
        {
            self.port = p
        } else {
            self.port = port
        }
    }

    func start() async throws {
        let server = try HTTPServer(
            address: .inet(ip4: Constants.serverIP, port: port),
            timeout: Constants.serverTimeout
        )

        // 모든 라우트 자동 등록
        for route in Route.allCases {
            await server.appendRoute(HTTPRoute(route.route), to: route.handler)
        }

        logger.info("IOSControl HTTP server started on port \(port)")
        try await server.run()
    }
}
