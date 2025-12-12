import Common
import FlyingFox
import Foundation
import XCTest

/// 하드웨어 버튼 누르기 핸들러
/// POST /device/button
struct PressButtonHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let body = try await JSONDecoder().decode(
                PressButtonRequestBody.self,
                from: request.bodyData,
            )

            switch body.button {
            case .home:
                XCUIDevice.shared.press(.home)
            #if !targetEnvironment(simulator)
                case .volumeUp:
                    XCUIDevice.shared.press(.volumeUp)
                case .volumeDown:
                    XCUIDevice.shared.press(.volumeDown)
            #else
                case .volumeUp, .volumeDown:
                    return .badRequest("Volume buttons are not available in Simulator")
            #endif
            }

            return .ok()
        } catch {
            return .badRequest("Invalid request: \(error)")
        }
    }
}
