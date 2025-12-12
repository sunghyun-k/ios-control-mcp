import Foundation

/// 실기기용 HTTP Transport
/// USBMux 터널을 통해 기기의 HTTP 서버와 통신
public final class USBMuxTransport: HTTPTransport, @unchecked Sendable {
    private let udid: String
    private let port: UInt16
    private let usbClient = USBMuxClient()
    private var cachedDeviceID: Int?

    public init(udid: String, port: UInt16 = 22087) {
        self.udid = udid
        self.port = port
    }

    // MARK: - HTTPTransport

    public func get(_ path: String) async throws -> (data: Data, statusCode: Int) {
        try await request("GET", path, body: nil)
    }

    public func post(_ path: String, body: Data?) async throws -> (data: Data, statusCode: Int) {
        try await request("POST", path, body: body)
    }

    // MARK: - Private

    private func getDeviceID() throws -> Int {
        if let cached = cachedDeviceID {
            return cached
        }

        let deviceID = try usbClient.findDeviceID(udid: udid)
        cachedDeviceID = deviceID
        return deviceID
    }

    private func request(
        _ method: String,
        _ path: String,
        body: Data?,
    ) async throws -> (data: Data, statusCode: Int) {
        // USB 연결
        let deviceID = try getDeviceID()
        let fd = try usbClient.connectToDevice(deviceID: deviceID, port: port)
        defer { close(fd) }

        // HTTP 요청 생성
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        var httpRequest = "\(method) \(normalizedPath) HTTP/1.1\r\n"
        httpRequest += "Host: localhost:\(port)\r\n"
        httpRequest += "Connection: close\r\n"

        if let body {
            httpRequest += "Content-Type: application/json\r\n"
            httpRequest += "Content-Length: \(body.count)\r\n"
        }

        httpRequest += "\r\n"

        // 요청 전송
        var requestData = Data(httpRequest.utf8)
        if let body {
            requestData.append(body)
        }

        let sendResult = requestData.withUnsafeBytes { bytes in
            send(fd, bytes.baseAddress, requestData.count, 0)
        }

        guard sendResult == requestData.count else {
            throw USBMuxTransportError.sendFailed(errno)
        }

        // 응답 수신
        return try readHTTPResponse(fd: fd)
    }

    private func readHTTPResponse(fd: Int32) throws -> (data: Data, statusCode: Int) {
        var buffer = Data()
        let chunkSize = 4096
        var chunk = Data(count: chunkSize)

        // 응답 읽기
        while true {
            let bytesRead = chunk.withUnsafeMutableBytes { bytes in
                recv(fd, bytes.baseAddress, chunkSize, 0)
            }

            if bytesRead < 0 {
                throw USBMuxTransportError.receiveFailed(errno)
            }

            if bytesRead == 0 {
                break // 연결 종료
            }

            buffer.append(chunk.prefix(bytesRead))

            // HTTP 응답 완료 여부 체크
            if buffer.count > 4,
               let headerEnd = findHeaderEnd(in: buffer)
            {
                if let contentLength = parseContentLength(from: buffer.prefix(headerEnd)) {
                    let totalExpected = headerEnd + 4 + contentLength
                    if buffer.count >= totalExpected {
                        break
                    }
                }
            }
        }

        // HTTP 응답 파싱
        return try parseHTTPResponse(buffer)
    }

    private func findHeaderEnd(in data: Data) -> Int? {
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A]) // \r\n\r\n
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
                let value = line.dropFirst("content-length:".count)
                    .trimmingCharacters(in: .whitespaces)
                return Int(value)
            }
        }
        return nil
    }

    private func parseHTTPResponse(_ data: Data) throws -> (data: Data, statusCode: Int) {
        // \r\n\r\n으로 헤더와 바디 분리
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A])
        guard let range = data.range(of: separator) else {
            throw USBMuxTransportError.invalidResponse
        }

        let headerData = data.prefix(upTo: range.lowerBound)
        let bodyData = data.suffix(from: range.upperBound)

        // 상태 코드 추출
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw USBMuxTransportError.invalidResponse
        }

        let statusLine = headerString.components(separatedBy: "\r\n").first ?? ""
        let parts = statusLine.components(separatedBy: " ")
        guard parts.count >= 2, let statusCode = Int(parts[1]) else {
            throw USBMuxTransportError.invalidResponse
        }

        return (Data(bodyData), statusCode)
    }
}

// MARK: - Errors

public enum USBMuxTransportError: Error, LocalizedError {
    case sendFailed(Int32)
    case receiveFailed(Int32)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .sendFailed(let errno):
            "Failed to send HTTP request: \(errno)"
        case .receiveFailed(let errno):
            "Failed to receive HTTP response: \(errno)"
        case .invalidResponse:
            "Invalid HTTP response"
        }
    }
}
