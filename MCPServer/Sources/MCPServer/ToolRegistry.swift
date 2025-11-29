import Foundation
import MCP
import Common
import IOSControlClient

/// 도구 레지스트리
/// 모든 MCP 도구를 관리하고 핸들러를 제공합니다.
enum ToolRegistry {
    /// 모든 Tool 객체
    static var allTools: [Tool] {
        [
            TapTool.tool,
            TapCoordinateTool.tool,
            SwipeTool.tool,
            ScrollTool.tool,
            InputTextTool.tool,
            GetUITreeTool.tool,
            GetForegroundAppTool.tool,
            ScreenshotTool.tool,
            ListAppsTool.tool,
            LaunchAppTool.tool,
            GoHomeTool.tool,
            TerminateAppTool.tool,
            OpenURLTool.tool,
            GetPasteboardTool.tool,
            SetPasteboardTool.tool,
            PinchTool.tool
        ]
    }

    /// 도구 이름으로 핸들러 조회 및 실행
    static func handle(name: String, arguments: [String: Value]?) async throws -> [Tool.Content] {
        let config = Configuration.default
        let client = IOSControlClient(host: config.agentHost, port: config.agentPort, httpTimeout: config.httpTimeout)

        // Agent 서버 실행 보장
        try await ensureServerRunning(client: client)

        switch name {
        case TapTool.name:
            return try await TapTool.handle(arguments: arguments, client: client)
        case TapCoordinateTool.name:
            return try await TapCoordinateTool.handle(arguments: arguments, client: client)
        case SwipeTool.name:
            return try await SwipeTool.handle(arguments: arguments, client: client)
        case ScrollTool.name:
            return try await ScrollTool.handle(arguments: arguments, client: client)
        case InputTextTool.name:
            return try await InputTextTool.handle(arguments: arguments, client: client)
        case GetUITreeTool.name:
            return try await GetUITreeTool.handle(arguments: arguments, client: client)
        case GetForegroundAppTool.name:
            return try await GetForegroundAppTool.handle(arguments: arguments, client: client)
        case ScreenshotTool.name:
            return try await ScreenshotTool.handle(arguments: arguments, client: client)
        case ListAppsTool.name:
            return try await ListAppsTool.handle(arguments: arguments, client: client)
        case LaunchAppTool.name:
            return try await LaunchAppTool.handle(arguments: arguments, client: client)
        case GoHomeTool.name:
            return try await GoHomeTool.handle(arguments: arguments, client: client)
        case TerminateAppTool.name:
            return try await TerminateAppTool.handle(arguments: arguments, client: client)
        case OpenURLTool.name:
            return try await OpenURLTool.handle(arguments: arguments, client: client)
        case GetPasteboardTool.name:
            return try await GetPasteboardTool.handle(arguments: arguments, client: client)
        case SetPasteboardTool.name:
            return try await SetPasteboardTool.handle(arguments: arguments, client: client)
        case PinchTool.name:
            return try await PinchTool.handle(arguments: arguments, client: client)
        default:
            throw IOSControlError.unknownTool(name)
        }
    }

    /// 서버가 실행 중인지 확인하고, 실행 중이지 않으면 SimulatorAgent 시작
    private static func ensureServerRunning(client: IOSControlClient) async throws {
        if await client.isServerRunning() {
            return
        }
        try await SimulatorAgentRunner.shared.start()
    }
}
