import FlyingFox
import Common
import XCTest

struct LaunchAppHandler: NoResponseHandler {
    typealias Request = LaunchAppRequest

    func handle(_ request: LaunchAppRequest) async throws {
        let app = XCUIApplication(bundleIdentifier: request.bundleId)
        app.launch()
    }
}
