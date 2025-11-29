import FlyingFox
import Common
import XCTest

struct ForegroundAppHandler: NoBodyHandler {
    typealias Response = ForegroundAppResponse

    private static let cardPattern = try! NSRegularExpression(pattern: #"^card:([^:]+):sceneID:"#)

    func handle() async throws -> ForegroundAppResponse {
        let springboard = XCUIApplication(bundleIdentifier: Constants.springboardBundleId)
        let snapshot = try springboard.snapshot()

        let bundleId = SnapshotUtils.findIdentifier(
            in: snapshot.dictionaryRepresentation,
            matching: Self.cardPattern
        )

        return ForegroundAppResponse(bundleId: bundleId)
    }
}
