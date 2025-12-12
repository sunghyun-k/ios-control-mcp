import Foundation

/// 시뮬레이터용 HTTP Transport
/// URLSession을 사용하여 localhost에 HTTP 요청
public final class URLSessionTransport: HTTPTransport, Sendable {
    private let baseURL: URL
    private let session: URLSession

    public init(port: Int = 22087) {
        baseURL = URL(string: "http://localhost:\(port)")!
        session = URLSession.shared
    }

    // MARK: - HTTPTransport

    public func get(_ path: String) async throws -> (data: Data, statusCode: Int) {
        let url = baseURL.appending(path: path)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPTransportError.connectionFailed(underlying: URLError(.badServerResponse))
        }

        return (data, httpResponse.statusCode)
    }

    public func post(_ path: String, body: Data?) async throws -> (data: Data, statusCode: Int) {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPTransportError.connectionFailed(underlying: URLError(.badServerResponse))
        }

        return (data, httpResponse.statusCode)
    }
}
