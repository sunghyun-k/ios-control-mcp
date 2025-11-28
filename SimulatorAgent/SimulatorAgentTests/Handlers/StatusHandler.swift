import FlyingFox
import Foundation
import Common

struct StatusHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"]
        let response = StatusResponse(status: "ok", udid: udid)
        let body = try JSONEncoder().encode(response)
        return HTTPResponse(statusCode: .ok, body: body)
    }
}
