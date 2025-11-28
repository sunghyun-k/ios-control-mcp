import FlyingFox
import Foundation

enum DecodeResult<T> {
    case success(T)
    case failure(HTTPResponse)
}

extension HTTPRequest {
    /// JSON 바디를 디코딩합니다. 실패 시 nil 반환.
    func decodeBody<T: Decodable>(_ type: T.Type) async -> T? {
        guard let data = try? await bodyData,
              let decoded = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return decoded
    }

    /// JSON 바디를 디코딩합니다. 실패 시 AppError의 HTTPResponse 반환.
    func decodeBodyOrError<T: Decodable>(_ type: T.Type) async -> DecodeResult<T> {
        guard let data = try? await bodyData else {
            return .failure(AppError(.badRequest, "Failed to read request body").httpResponse)
        }
        guard let decoded = try? JSONDecoder().decode(type, from: data) else {
            return .failure(AppError(.badRequest, "Invalid \(T.self) request body").httpResponse)
        }
        return .success(decoded)
    }
}
