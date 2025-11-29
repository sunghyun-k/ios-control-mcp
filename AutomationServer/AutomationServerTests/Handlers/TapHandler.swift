import FlyingFox
import Common
import XCTest

struct TapHandler: NoResponseHandler {
    typealias Request = TapRequest

    func handle(_ request: TapRequest) async throws {
        let point = CGPoint(x: request.x, y: request.y)
        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.addPointerTouchEvent(at: point, touchUpAfter: request.duration)
        try await RunnerDaemonProxy.shared.synthesize(eventRecord: eventRecord)
    }
}
