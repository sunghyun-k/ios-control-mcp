import Foundation
import iOSAutomation
import MCP

/// MCP 도구 레지스트리
/// 모든 도구를 관리하고 핸들러를 제공
enum ToolRegistry {
    private static let automation = iOSAutomation()

    /// 등록된 모든 도구 타입
    /// 새 도구를 추가하려면 여기에만 추가하면 됨
    private static let toolTypes: [any MCPToolDefinition.Type] = [
        // 기기 관리 (먼저 호출해야 함)
        ListDevicesTool.self,
        SelectDeviceTool.self,
        // UI 조회
        GetUISnapshotTool.self,
        ScreenshotTool.self,
        // UI 조작
        TapTool.self,
        TypeTextTool.self,
        SwipeTool.self,
        DragTool.self,
        // 앱 관리
        LaunchAppTool.self,
        // 디바이스
        PressButtonTool.self,
    ]

    /// 모든 Tool 객체
    static var allTools: [Tool] {
        var tools: [Tool] = []
        for toolType in toolTypes {
            tools.append(toolType.tool)
        }
        return tools
    }

    /// 도구 이름으로 핸들러 조회 및 실행
    static func handle(name: String, arguments: [String: Value]?) async throws -> [Tool.Content] {
        guard let toolType = toolTypes.first(where: { $0.name == name }) else {
            throw ToolError.unknownTool(name)
        }
        return try await toolType.execute(arguments: arguments, automation: automation)
    }
}

enum ToolError: LocalizedError {
    case unknownTool(String)
    case missingArgument(String)
    case invalidArgument(String)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            "Unknown tool: \(name)"
        case .missingArgument(let name):
            "Missing required argument: \(name)"
        case .invalidArgument(let message):
            "Invalid argument: \(message)"
        }
    }
}
