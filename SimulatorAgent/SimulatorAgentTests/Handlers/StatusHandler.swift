import FlyingFox
import Foundation
import Common

struct StatusHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let response = StatusResponse(status: "ok")
        let body = try JSONEncoder().encode(response)
        return HTTPResponse(statusCode: .ok, body: body)
    }
}
