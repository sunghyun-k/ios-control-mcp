import Foundation
import MCP
import IOSControlClient

struct ScreenshotTool: MCPTool {
    static let name = "screenshot"

    static let description = "현재 화면의 스크린샷을 캡처합니다. PNG 이미지를 반환합니다. 시각적 확인이 필요한 경우에만 사용하세요 (예: 이미지, 색상, 레이아웃 확인). 일반적인 UI 탐색에는 get_ui_tree를 사용하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        let data = try await client.screenshot()
        let base64 = data.base64EncodedString()
        return [.image(data: base64, mimeType: "image/png", metadata: nil)]
    }
}
