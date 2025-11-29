import Foundation
import MCP
import IOSControlClient

struct LaunchAppTool: MCPTool {
    static let name = "launch_app"

    static let description = "번들 ID로 앱을 실행합니다. 번들 ID는 list_apps로 확인하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "bundle_id": .object(["type": .string("string"), "description": .string("실행할 앱의 번들 ID")])
        ]),
        "required": .array([.string("bundle_id")])
    ])

    typealias Arguments = BundleIdArgs

    static func execute(args: BundleIdArgs, client: any AgentClient) async throws -> [Tool.Content] {
        try await client.launchApp(bundleId: args.bundleId)
        return [.text("launched \(args.bundleId)")]
    }
}
