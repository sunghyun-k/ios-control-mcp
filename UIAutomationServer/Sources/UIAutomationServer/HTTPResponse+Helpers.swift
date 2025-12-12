import FlyingFox
import Foundation

extension HTTPResponse {
    // MARK: - Success Responses

    static func ok(_ message: String = "OK") -> HTTPResponse {
        HTTPResponse(statusCode: .ok, body: Data(message.utf8))
    }

    static func json(_ data: Data) -> HTTPResponse {
        HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "application/json"],
            body: data,
        )
    }

    static func png(_ data: Data) -> HTTPResponse {
        HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "image/png"],
            body: data,
        )
    }

    // MARK: - Error Responses

    static func badRequest(_ message: String) -> HTTPResponse {
        HTTPResponse(statusCode: .badRequest, body: Data(message.utf8))
    }

    static func notFound(_ message: String) -> HTTPResponse {
        HTTPResponse(statusCode: .notFound, body: Data(message.utf8))
    }

    static func serverError(_ message: String) -> HTTPResponse {
        HTTPResponse(statusCode: .internalServerError, body: Data(message.utf8))
    }
}
