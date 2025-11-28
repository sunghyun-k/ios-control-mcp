import FlyingFox
import Common
import XCTest

struct ListAppsHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let icons = springboard.icons.allElementsBoundByIndex

            var bundleIds: [String] = []
            for icon in icons {
                let identifier = icon.identifier
                // 앱 아이콘의 identifier는 보통 번들 ID 형식
                if !identifier.isEmpty && identifier.contains(".") {
                    bundleIds.append(identifier)
                }
            }

            // 중복 제거 및 정렬
            let uniqueBundleIds = Array(Set(bundleIds)).sorted()

            let response = ListAppsResponse(bundleIds: uniqueBundleIds)
            let body = try JSONEncoder().encode(response)
            return HTTPResponse(statusCode: .ok, body: body)
        } catch {
            return AppError(.internal, "Failed to list apps: \(error.localizedDescription)").httpResponse
        }
    }
}
