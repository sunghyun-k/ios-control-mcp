import FlyingFox
import Common
import XCTest

struct GoHomeHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            XCUIDevice.shared.press(.home)
            return HTTPResponse(statusCode: .ok)
        } catch {
            return AppError(.internal, "Failed to go home: \(error.localizedDescription)").httpResponse
        }
    }
}
