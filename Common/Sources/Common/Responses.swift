import Foundation

/// 상태 응답
public struct StatusResponse: Codable, Sendable {
    public let status: String
    public let udid: String?

    public init(status: String, udid: String? = nil) {
        self.status = status
        self.udid = udid
    }
}

/// UI 트리 응답
public struct TreeResponse: Codable, Sendable {
    public let tree: AXElement

    public init(tree: AXElement) {
        self.tree = tree
    }
}

/// 포그라운드 앱 응답
public struct ForegroundAppResponse: Codable, Sendable {
    public let bundleId: String?

    public init(bundleId: String?) {
        self.bundleId = bundleId
    }
}

/// 설치된 앱 목록 응답
public struct ListAppsResponse: Codable, Sendable {
    public let bundleIds: [String]

    public init(bundleIds: [String]) {
        self.bundleIds = bundleIds
    }
}

/// 클립보드 내용 응답
public struct GetPasteboardResponse: Codable, Sendable {
    public let content: String?

    public init(content: String?) {
        self.content = content
    }
}
