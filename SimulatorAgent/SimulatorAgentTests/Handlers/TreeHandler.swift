import FlyingFox
import Common
import XCTest

struct TreeHandler: HTTPHandler {
    private static let springboardBundleId = "com.apple.springboard"

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let treeRequest = await request.decodeBody(TreeRequest.self)
            let bundleId = treeRequest?.appBundleId

            let app: XCUIApplication
            if let bundleId = bundleId, !bundleId.isEmpty {
                app = XCUIApplication(bundleIdentifier: bundleId)
            } else {
                app = XCUIApplication(bundleIdentifier: Self.springboardBundleId)
            }

            let snapshot = try app.snapshot()
            let axElement = SnapshotUtils.convertToAXElement(snapshot.dictionaryRepresentation)

            let response = TreeResponse(tree: axElement)
            let body = try JSONEncoder().encode(response)
            return HTTPResponse(statusCode: .ok, body: body)
        } catch {
            return AppError(.internal, "Tree fetch failed: \(error.localizedDescription)").httpResponse
        }
    }
}
