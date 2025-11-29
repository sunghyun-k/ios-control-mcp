import FlyingFox
import Common
import XCTest

struct PinchHandler: NoResponseHandler {
    typealias Request = PinchRequest

    func handle(_ request: PinchRequest) async throws {
        let center = CGPoint(x: request.x, y: request.y)
        let eventRecord = EventRecord(orientation: .portrait, style: .multiFinger)
        _ = eventRecord.addPinchEvent(center: center, scale: request.scale, velocity: request.velocity)
        try await RunnerDaemonProxy.shared.synthesize(eventRecord: eventRecord)
    }
}
