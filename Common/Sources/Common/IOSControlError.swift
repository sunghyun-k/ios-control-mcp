import Foundation

/// IOSControl 오류
public enum IOSControlError: Error, LocalizedError {
    case serverNotRunning
    case invalidResponse
    case httpError(Int)
    case elementNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .serverNotRunning:
            return "IOSControl 서버가 실행 중이지 않습니다"
        case .invalidResponse:
            return "잘못된 응답"
        case .httpError(let code):
            return "HTTP 오류: \(code)"
        case .elementNotFound(let label):
            return "요소를 찾을 수 없습니다: \(label)"
        }
    }
}
