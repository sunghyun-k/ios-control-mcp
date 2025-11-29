import Foundation
import MCP
import IOSControlClient

/// MCP 도구 프로토콜
/// 각 도구는 이 프로토콜을 구현하여 독립적인 파일로 분리됩니다.
protocol MCPTool {
    /// 도구 이름
    static var name: String { get }

    /// 도구 설명
    static var description: String { get }

    /// 입력 스키마
    static var inputSchema: Value { get }

    /// 연결된 인자 타입
    associatedtype Arguments: ToolArguments

    /// 도구 실행
    static func execute(args: Arguments, client: any AgentClient) async throws -> [Tool.Content]
}

extension MCPTool {
    /// Tool 객체 생성
    static var tool: Tool {
        Tool(
            name: name,
            description: description,
            inputSchema: inputSchema
        )
    }

    /// 핸들러 래핑
    static func handle(arguments: [String: Value]?, client: any AgentClient) async throws -> [Tool.Content] {
        let args = try Arguments(from: arguments)
        return try await execute(args: args, client: client)
    }
}
