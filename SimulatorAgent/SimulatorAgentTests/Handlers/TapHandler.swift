import FlyingFox
import Common
import XCTest

struct TapHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(TapRequest.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                let point = CGPoint(x: body.x, y: body.y)
                let eventRecord = EventRecord(orientation: .portrait)
                _ = eventRecord.addPointerTouchEvent(at: point, touchUpAfter: body.duration)
                try await RunnerDaemonProxy.shared.synthesize(eventRecord: eventRecord)
                return HTTPResponse(statusCode: .ok)
            } catch {
                return AppError(.internal, "Tap failed: \(error.localizedDescription)").httpResponse
            }
        }
    }
}
