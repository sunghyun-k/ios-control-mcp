import Foundation

/// HTTP 전송 계층 프로토콜
/// 시뮬레이터(URLSession)와 실기기(USBMux)에서 동일한 인터페이스 사용
public protocol HTTPTransport: Sendable {
    /// GET 요청
    func get(_ path: String) async throws -> (data: Data, statusCode: Int)

    /// POST 요청
    func post(_ path: String, body: Data?) async throws -> (data: Data, statusCode: Int)
}

// MARK: - Transport Errors

public enum HTTPTransportError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, body: Data?)
    case connectionFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .httpError(let statusCode, _):
            "HTTP error: \(statusCode)"
        case .connectionFailed(let error):
            "Connection failed: \(error.localizedDescription)"
        }
    }
}
