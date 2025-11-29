import FlyingFox
import Common
import XCTest

struct InputTextHandler: NoResponseHandler {
    typealias Request = InputTextRequest

    func handle(_ request: InputTextRequest) async throws {
        try await RunnerDaemonProxy.shared.send(string: request.text)
    }
}
