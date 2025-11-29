import Foundation
import Common

/// USB를 통한 HTTP 클라이언트 (실기기용)
/// usbmuxd 연결을 사용하여 실기기의 Agent와 HTTP 통신
public final class USBHTTPClient: AgentClient, @unchecked Sendable {
    private let deviceID: Int
    private let port: UInt16

    public init(deviceID: Int, port: UInt16 = 22087) {
        self.deviceID = deviceID
        self.port = port
    }

    // MARK: - HTTP Methods

    public func get(_ endpoint: String) async throws -> Data {
        try await request("GET", endpoint, body: nil)
    }

    public func post<T: Encodable>(_ endpoint: String, body: T) async throws -> Data {
        let bodyData = try JSONEncoder().encode(body)
        return try await request("POST", endpoint, body: bodyData)
    }

    // MARK: - Core Request

    private func request(_ method: String, _ endpoint: String, body: Data?) async throws -> Data {
        // USB 연결
        let usbClient = USBMuxClient()
        let fd = try usbClient.connectToDevice(deviceID: deviceID, port: port)

        defer {
            close(fd)
        }

        // HTTP 요청 생성
        let path = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        var httpRequest = "\(method) \(path) HTTP/1.1\r\n"
        httpRequest += "Host: localhost:\(port)\r\n"
        httpRequest += "Connection: close\r\n"

        if let body = body {
            httpRequest += "Content-Type: application/json\r\n"
            httpRequest += "Content-Length: \(body.count)\r\n"
        }

        httpRequest += "\r\n"

        // 요청 전송
        var requestData = Data(httpRequest.utf8)
        if let body = body {
            requestData.append(body)
        }

        let sendResult = requestData.withUnsafeBytes { bytes in
            send(fd, bytes.baseAddress, requestData.count, 0)
        }

        guard sendResult == requestData.count else {
            throw USBHTTPError.sendFailed(errno)
        }

        // 응답 수신
        let response = try await readHTTPResponse(fd: fd)
        return response
    }

    private func readHTTPResponse(fd: Int32) async throws -> Data {
        var buffer = Data()
        let chunkSize = 4096
        var chunk = Data(count: chunkSize)

        // 응답 읽기
        while true {
            let bytesRead = chunk.withUnsafeMutableBytes { bytes in
                recv(fd, bytes.baseAddress, chunkSize, 0)
            }

            if bytesRead < 0 {
                throw USBHTTPError.receiveFailed(errno)
            }

            if bytesRead == 0 {
                break  // 연결 종료
            }

            buffer.append(chunk.prefix(bytesRead))

            // 간단한 종료 조건 체크 (Connection: close이므로 서버가 연결을 닫을 때까지 읽음)
            // 충분한 데이터가 왔는지 체크
            if buffer.count > 4 {
                // HTTP 응답 완료 여부 체크
                if let headerEnd = findHeaderEnd(in: buffer) {
                    // Content-Length 확인
                    if let contentLength = parseContentLength(from: buffer.prefix(headerEnd)) {
                        let totalExpected = headerEnd + 4 + contentLength  // header + \r\n\r\n + body
                        if buffer.count >= totalExpected {
                            break
                        }
                    } else {
                        // Content-Length 없으면 연결 종료까지 읽음
                        continue
                    }
                }
            }
        }

        // HTTP 응답 파싱
        return try parseHTTPResponse(buffer)
    }

    private func findHeaderEnd(in data: Data) -> Int? {
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A])  // \r\n\r\n
        if let range = data.range(of: separator) {
            return range.lowerBound
        }
        return nil
    }

    private func parseContentLength(from headerData: Data) -> Int? {
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let lines = headerString.components(separatedBy: "\r\n")
        for line in lines {
            if line.lowercased().hasPrefix("content-length:") {
                let value = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                return Int(value)
            }
        }
        return nil
    }

    private func parseHTTPResponse(_ data: Data) throws -> Data {
        // \r\n\r\n으로 헤더와 바디 분리
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A])
        guard let range = data.range(of: separator) else {
            throw USBHTTPError.invalidResponse
        }

        let headerData = data.prefix(upTo: range.lowerBound)
        let bodyData = data.suffix(from: range.upperBound)

        // 상태 코드 확인
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw USBHTTPError.invalidResponse
        }

        let statusLine = headerString.components(separatedBy: "\r\n").first ?? ""
        let parts = statusLine.components(separatedBy: " ")
        guard parts.count >= 2, let statusCode = Int(parts[1]) else {
            throw USBHTTPError.invalidResponse
        }

        if statusCode >= 400 {
            throw USBHTTPError.httpError(statusCode)
        }

        return Data(bodyData)
    }
}

// MARK: - AgentClient Protocol

extension USBHTTPClient {
    /// 서버 상태 확인
    public func status() async throws -> StatusResponse {
        let data = try await get("status")
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }

    /// UI 트리 조회
    public func tree(appBundleId: String? = nil) async throws -> TreeResponse {
        let data = try await post("tree", body: TreeRequest(appBundleId: appBundleId))
        return try JSONDecoder().decode(TreeResponse.self, from: data)
    }

    /// 포그라운드 앱
    public func foregroundApp() async throws -> ForegroundAppResponse {
        let data = try await get("foregroundApp")
        return try JSONDecoder().decode(ForegroundAppResponse.self, from: data)
    }

    /// 스크린샷
    public func screenshot(format: String = "png") async throws -> Data {
        try await get("screenshot?format=\(format)")
    }

    /// 탭
    public func tap(_ request: TapRequest) async throws {
        _ = try await post("tap", body: request)
    }

    /// 스와이프
    public func swipe(_ request: SwipeRequest) async throws {
        _ = try await post("swipe", body: request)
    }

    /// 핀치
    public func pinch(_ request: PinchRequest) async throws {
        _ = try await post("pinch", body: request)
    }

    /// 텍스트 입력
    public func inputText(_ request: InputTextRequest) async throws {
        _ = try await post("inputText", body: request)
    }

    /// 앱 실행
    public func launchApp(bundleId: String) async throws {
        _ = try await post("launchApp", body: LaunchAppRequest(bundleId: bundleId))
    }

    /// 홈으로 이동
    public func goHome() async throws {
        _ = try await get("goHome")
    }
}

// MARK: - Errors

public enum USBHTTPError: Error, LocalizedError {
    case sendFailed(Int32)
    case receiveFailed(Int32)
    case invalidResponse
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .sendFailed(let errno):
            return "Failed to send HTTP request: \(errno)"
        case .receiveFailed(let errno):
            return "Failed to receive HTTP response: \(errno)"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
