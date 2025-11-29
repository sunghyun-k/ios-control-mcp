import Foundation
import MCP
import IOSControlClient

struct TerminateAppTool: MCPTool {
    static let name = "terminate_app"

    static let description = "실행 중인 앱을 강제 종료합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "bundle_id": .object(["type": .string("string"), "description": .string("종료할 앱의 번들 ID")])
        ]),
        "required": .array([.string("bundle_id")])
    ])

    typealias Arguments = BundleIdArgs

    static func execute(args: BundleIdArgs, client: any AgentClient) async throws -> [Tool.Content] {
        try await client.terminateApp(bundleId: args.bundleId)
        return [.text("terminated \(args.bundleId)")]
    }
}
