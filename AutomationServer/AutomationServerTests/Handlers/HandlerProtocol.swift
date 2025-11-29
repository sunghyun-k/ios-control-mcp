import FlyingFox
import Foundation

/// HTTP 핸들러 프로토콜
/// 요청 파싱과 에러 처리를 통합합니다.
protocol AgentHandler: HTTPHandler {
    associatedtype Request: Decodable
    associatedtype Response: Encodable

    /// 요청을 처리하고 응답을 반환합니다.
    func handle(_ request: Request) async throws -> Response
}

/// 요청 바디가 필요 없는 핸들러
protocol NoBodyHandler: HTTPHandler {
    associatedtype Response: Encodable

    /// 요청을 처리하고 응답을 반환합니다.
    func handle() async throws -> Response
}

/// 응답이 없는 핸들러 (200 OK만 반환)
protocol NoResponseHandler: HTTPHandler {
    associatedtype Request: Decodable

    /// 요청을 처리합니다.
    func handle(_ request: Request) async throws
}

/// 요청/응답 모두 없는 핸들러
protocol SimpleHandler: HTTPHandler {
    /// 요청을 처리합니다.
    func handle() async throws
}

// MARK: - Default Implementations

extension AgentHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(Request.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                let response = try await handle(body)
                let data = try JSONEncoder().encode(response)
                return HTTPResponse(statusCode: .ok, body: data)
            } catch {
                return AppError(.internal, "\(error.localizedDescription)").httpResponse
            }
        }
    }
}

extension NoBodyHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let response = try await handle()
            let data = try JSONEncoder().encode(response)
            return HTTPResponse(statusCode: .ok, body: data)
        } catch {
            return AppError(.internal, "\(error.localizedDescription)").httpResponse
        }
    }
}

extension NoResponseHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        switch await request.decodeBodyOrError(Request.self) {
        case .failure(let errorResponse):
            return errorResponse
        case .success(let body):
            do {
                try await handle(body)
                return HTTPResponse(statusCode: .ok)
            } catch {
                return AppError(.internal, "\(error.localizedDescription)").httpResponse
            }
        }
    }
}

extension SimpleHandler {
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            try await handle()
            return HTTPResponse(statusCode: .ok)
        } catch {
            return AppError(.internal, "\(error.localizedDescription)").httpResponse
        }
    }
}

// MARK: - Empty Types

/// 빈 요청 타입
struct EmptyRequest: Decodable {}

/// 빈 응답 타입
struct EmptyResponse: Encodable {}
