import Foundation
import MCP
import IOSControlClient

struct GetUITreeTool: MCPTool {
    static let name = "get_ui_tree"

    static let description = "현재 화면의 UI 요소 트리를 반환합니다. tap, drag 등에서 사용할 라벨을 확인할 수 있습니다. 키보드가 열려 있으면 요소가 가려질 수 있으니 키보드 위쪽을 탭하거나 스크롤하여 키보드를 닫은 후 조회하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "show_coords": .object(["type": .string("boolean"), "description": .string("좌표 표시 여부. 기본값 false. tap_coordinate 사용 시에만 true로 설정하세요.")])
        ])
    ])

    typealias Arguments = GetUITreeArgs

    static func execute(args: GetUITreeArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let appBundleId = try await client.foregroundApp().bundleId
        let showCoords = args.showCoords ?? false

        let response = try await client.tree(appBundleId: appBundleId)
        return [.text(TreeFormatter.format(response.tree, showCoords: showCoords))]
    }
}
