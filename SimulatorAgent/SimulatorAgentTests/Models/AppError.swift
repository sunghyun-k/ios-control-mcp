import Foundation
import FlyingFox

enum AppErrorCode: String, Codable {
    case badRequest
    case notFound
    case timeout
    case `internal`
}

struct AppError: Error, Codable {
    let code: AppErrorCode
    let message: String

    init(_ code: AppErrorCode = .internal, _ message: String) {
        self.code = code
        self.message = message
    }

    var httpResponse: HTTPResponse {
        let statusCode: HTTPStatusCode = switch code {
        case .badRequest: .badRequest
        case .notFound: .notFound
        case .timeout: .requestTimeout
        case .internal: .internalServerError
        }
        let body = (try? JSONEncoder().encode(self)) ?? Data()
        return HTTPResponse(statusCode: statusCode, body: body)
    }
}
