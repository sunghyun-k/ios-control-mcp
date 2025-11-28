import XCTest
import os

final class SimulatorAgentTests: XCTestCase {

    private static let logger = Logger(subsystem: "ios-control", category: "SimulatorAgentTests")

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testRunServer() async throws {
        let server = IOSControlServer()
        Self.logger.info("Starting IOSControl HTTP server")
        try await server.start()
    }
}
