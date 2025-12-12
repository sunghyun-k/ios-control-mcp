import FlyingFox

/// Health check 핸들러
struct HealthHandler: HTTPHandler {
    func handleRequest(_: HTTPRequest) async throws -> HTTPResponse {
        .ok()
    }
}
