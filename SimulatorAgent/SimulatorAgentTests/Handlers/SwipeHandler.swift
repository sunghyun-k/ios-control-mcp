import FlyingFox
import Common
import XCTest

struct SwipeHandler: NoResponseHandler {
    typealias Request = SwipeRequest

    func handle(_ request: SwipeRequest) async throws {
        let start = CGPoint(x: request.startX, y: request.startY)
        let end = CGPoint(x: request.endX, y: request.endY)
        let eventRecord = EventRecord(orientation: .portrait)
        _ = eventRecord.addSwipeEvent(start: start, end: end, duration: request.duration, holdDuration: request.holdDuration)
        try await RunnerDaemonProxy.shared.synthesize(eventRecord: eventRecord)
    }
}
