import FlyingFox
import Foundation
import Common

struct StatusHandler: NoBodyHandler {
    typealias Response = StatusResponse

    func handle() async throws -> StatusResponse {
        let udid = ProcessInfo.processInfo.environment[Constants.simulatorUdidEnvKey]
        return StatusResponse(status: "ok", udid: udid)
    }
}
