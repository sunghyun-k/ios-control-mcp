import FlyingFox
import Common
import XCTest

struct TreeHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let treeRequest = await request.decodeBody(TreeRequest.self)
            let bundleId = treeRequest?.appBundleId

            let app: XCUIApplication
            if let bundleId = bundleId, !bundleId.isEmpty {
                app = XCUIApplication(bundleIdentifier: bundleId)
            } else {
                app = XCUIApplication(bundleIdentifier: Constants.springboardBundleId)
            }

            let snapshot = try app.snapshot()

            // Live element에서 키보드 포커스 정보 수집
            let focusedIdentifiers = collectKeyboardFocusedIdentifiers(from: app)

            let axElement = SnapshotUtils.convertToAXElement(
                snapshot.dictionaryRepresentation,
                focusedIdentifiers: focusedIdentifiers
            )

            let response = TreeResponse(tree: axElement)
            let body = try JSONEncoder().encode(response)
            return HTTPResponse(statusCode: .ok, body: body)
        } catch {
            return AppError(.internal, "Tree fetch failed: \(error.localizedDescription)").httpResponse
        }
    }

    /// Live XCUIElement에서 hasKeyboardFocus가 true인 요소들의 identifier 수집
    private func collectKeyboardFocusedIdentifiers(from app: XCUIApplication) -> Set<String> {
        var focused = Set<String>()

        // TextField, SecureTextField, TextView, SearchField 쿼리
        let textFields = app.textFields.allElementsBoundByIndex
        let secureTextFields = app.secureTextFields.allElementsBoundByIndex
        let textViews = app.textViews.allElementsBoundByIndex
        let searchFields = app.searchFields.allElementsBoundByIndex

        for element in textFields + secureTextFields + textViews + searchFields {
            if let hasFocus = element.value(forKey: "hasKeyboardFocus") as? Bool, hasFocus {
                // identifier가 비어있으면 label 사용
                let id = element.identifier.isEmpty ? element.label : element.identifier
                if !id.isEmpty {
                    focused.insert(id)
                }
            }
        }

        return focused
    }
}
