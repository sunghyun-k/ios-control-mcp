import FlyingFox
import Foundation
import XCTest

/// 앱 스냅샷 핸들러
/// GET /apps/:bundleId/snapshot
struct SnapshotHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }

        guard let app = XCUIApplication.app(bundleId: bundleId) else {
            return .notFound("App not found")
        }

        do {
            let snapshot = try app.snapshot()
            let dict = snapshot.dictionaryRepresentation
            let data = try JSONSerialization.data(withJSONObject: dict)
            return .json(data)
        } catch {
            return .serverError("Snapshot failed: \(error)")
        }
    }
}
