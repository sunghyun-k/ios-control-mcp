import Foundation
import MCP
import IOSControlClient

struct GetUITreeTool: MCPTool {
    static let name = "get_ui_tree"

    static let description = "현재 화면의 UI 트리를 반환합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "app_bundle_id": .object(["type": .string("string"), "description": .string("앱 번들 ID")]),
            "show_coords": .object(["type": .string("boolean"), "description": .string("좌표 표시 여부. 기본값 false. tap_coordinate 사용 시에만 true로 설정하세요.")])
        ])
    ])

    typealias Arguments = GetUITreeArgs

    static func execute(args: GetUITreeArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        var appBundleId = args.appBundleId
        if appBundleId == nil {
            appBundleId = try await client.foregroundApp().bundleId
        }
        let showCoords = args.showCoords ?? false

        let response = try await client.tree(appBundleId: appBundleId)
        return [.text(TreeFormatter.format(response.tree, showCoords: showCoords))]
    }
}
