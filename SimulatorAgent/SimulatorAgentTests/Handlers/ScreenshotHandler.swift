import FlyingFox
import XCTest

struct ScreenshotHandler: HTTPHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let format = request.query.first(where: { $0.name == "format" })?.value ?? "png"

        let screenshot = XCUIScreen.main.screenshot()

        let imageData: Data?
        let contentType: String

        if format == "jpeg" || format == "jpg" {
            let quality = Double(request.query.first(where: { $0.name == "quality" })?.value ?? "0.8") ?? 0.8
            imageData = screenshot.image.jpegData(compressionQuality: quality)
            contentType = "image/jpeg"
        } else {
            imageData = screenshot.pngRepresentation
            contentType = "image/png"
        }

        guard let data = imageData else {
            return AppError(.internal, "Failed to capture screenshot").httpResponse
        }

        return HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: contentType],
            body: data
        )
    }
}
