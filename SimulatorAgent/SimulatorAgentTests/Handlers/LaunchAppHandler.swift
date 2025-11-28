import FlyingFox
import Common
import XCTest

struct LaunchAppHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(LaunchAppRequest.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                let app = XCUIApplication(bundleIdentifier: body.bundleId)
                app.launch()

                return HTTPResponse(statusCode: .ok)
            } catch {
                return AppError(.internal, "Failed to launch app: \(error.localizedDescription)").httpResponse
            }
        }
    }
}
