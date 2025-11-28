import FlyingFox
import Common
import XCTest

struct ForegroundAppHandler: HTTPHandler {
    private static let springboardBundleId = "com.apple.springboard"
    private static let cardPattern = try! NSRegularExpression(pattern: #"^card:([^:]+):sceneID:"#)

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let springboard = XCUIApplication(bundleIdentifier: Self.springboardBundleId)
            let snapshot = try springboard.snapshot()

            let bundleId = SnapshotUtils.findIdentifier(
                in: snapshot.dictionaryRepresentation,
                matching: Self.cardPattern
            )

            let response = ForegroundAppResponse(bundleId: bundleId)
            let body = try JSONEncoder().encode(response)
            return HTTPResponse(statusCode: .ok, body: body)
        } catch {
            return AppError(.internal, "Failed to get foreground app: \(error.localizedDescription)").httpResponse
        }
    }
}
