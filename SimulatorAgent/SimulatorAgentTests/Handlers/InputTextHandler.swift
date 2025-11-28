import FlyingFox
import Common
import XCTest

struct InputTextHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(InputTextRequest.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                try await RunnerDaemonProxy.shared.send(string: body.text, typingFrequency: 30)
                return HTTPResponse(statusCode: .ok)
            } catch {
                return AppError(.internal, "Text input failed: \(error.localizedDescription)").httpResponse
            }
        }
    }
}
