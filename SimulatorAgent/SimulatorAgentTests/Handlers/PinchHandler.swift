import FlyingFox
import Common
import XCTest

struct PinchHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(PinchRequest.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                let center = CGPoint(x: body.x, y: body.y)
                let eventRecord = EventRecord(orientation: .portrait, style: .multiFinger)
                _ = eventRecord.addPinchEvent(center: center, scale: body.scale, velocity: body.velocity)
                try await RunnerDaemonProxy.shared.synthesize(eventRecord: eventRecord)
                return HTTPResponse(statusCode: .ok)
            } catch {
                return AppError(.internal, "Pinch failed: \(error.localizedDescription)").httpResponse
            }
        }
    }
}
