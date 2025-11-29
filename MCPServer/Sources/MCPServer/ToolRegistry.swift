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
            // 기기 관리
            ListDevicesTool.tool,
            SelectDeviceTool.tool,
            // UI 조작
            TapTool.tool,
            TapCoordinateTool.tool,
            SwipeTool.tool,
            ScrollTool.tool,
            DragTool.tool,
            InputTextTool.tool,
            PinchTool.tool,
            // 정보 조회
            GetUITreeTool.tool,
            GetForegroundAppTool.tool,
            ScreenshotTool.tool,
            // 앱 관리
            ListAppsTool.tool,
            LaunchAppTool.tool,
            GoHomeTool.tool
        ]
    }

    /// 도구 이름으로 핸들러 조회 및 실행
    static func handle(name: String, arguments: [String: Value]?) async throws -> [Tool.Content] {
        // 선택된 기기(또는 자동 선택)에 맞는 클라이언트 획득
        let client = try await DeviceManager.shared.getOrAutoSelectAgentClient()

        // Agent 서버 실행 보장 (시뮬레이터의 경우에만)
        try await ensureServerRunning(client: client)

        switch name {
        // 기기 관리 (Agent 없이 동작)
        case ListDevicesTool.name:
            return try await ListDevicesTool.handle(arguments: arguments, client: client)
        case SelectDeviceTool.name:
            return try await SelectDeviceTool.handle(arguments: arguments, client: client)
        // UI 조작
        case TapTool.name:
            return try await TapTool.handle(arguments: arguments, client: client)
        case TapCoordinateTool.name:
            return try await TapCoordinateTool.handle(arguments: arguments, client: client)
        case SwipeTool.name:
            return try await SwipeTool.handle(arguments: arguments, client: client)
        case ScrollTool.name:
            return try await ScrollTool.handle(arguments: arguments, client: client)
        case DragTool.name:
            return try await DragTool.handle(arguments: arguments, client: client)
        case InputTextTool.name:
            return try await InputTextTool.handle(arguments: arguments, client: client)
        case PinchTool.name:
            return try await PinchTool.handle(arguments: arguments, client: client)
        // 정보 조회
        case GetUITreeTool.name:
            return try await GetUITreeTool.handle(arguments: arguments, client: client)
        case GetForegroundAppTool.name:
            return try await GetForegroundAppTool.handle(arguments: arguments, client: client)
        case ScreenshotTool.name:
            return try await ScreenshotTool.handle(arguments: arguments, client: client)
        // 앱 관리
        case ListAppsTool.name:
            return try await ListAppsTool.handle(arguments: arguments, client: client)
        case LaunchAppTool.name:
            return try await LaunchAppTool.handle(arguments: arguments, client: client)
        case GoHomeTool.name:
            return try await GoHomeTool.handle(arguments: arguments, client: client)
        default:
            throw IOSControlError.unknownTool(name)
        }
    }

    /// 서버가 실행 중인지 확인하고, 필요시 Agent 시작
    private static func ensureServerRunning(client: any AgentClient) async throws {
        if await client.isServerRunning() {
            return
        }

        guard let device = try await DeviceManager.shared.getCurrentDevice() else {
            return
        }

        switch device.type {
        case .simulator:
            try await SimulatorAgentRunner.shared.start()

        case .physical:
            try await DeviceAgentRunner.shared.start(udid: device.id)
        }
    }
}
