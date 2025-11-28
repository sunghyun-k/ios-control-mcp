import FlyingFox
import Common
import XCTest

struct SwipeHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(SwipeRequest.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                let start = CGPoint(x: body.startX, y: body.startY)
                let end = CGPoint(x: body.endX, y: body.endY)
                let eventRecord = EventRecord(orientation: .portrait)
                _ = eventRecord.addSwipeEvent(start: start, end: end, duration: body.duration)
                try await RunnerDaemonProxy.shared.synthesize(eventRecord: eventRecord)
                return HTTPResponse(statusCode: .ok)
            } catch {
                return AppError(.internal, "Swipe failed: \(error.localizedDescription)").httpResponse
            }
        }
    }
}
