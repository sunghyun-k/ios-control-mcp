import FlyingFox
import Common
import XCTest

struct GoHomeHandler: SimpleHandler {
    func handle() async throws {
        XCUIDevice.shared.press(.home)
    }
}
