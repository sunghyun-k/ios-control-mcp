import Foundation
import MCP
import Common
import IOSControlClient

struct TapTool: MCPTool {
    static let name = "tap"

    static let description = "라벨로 UI 요소를 찾아 탭합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "label": .object(["type": .string("string"), "description": .string("찾을 요소의 라벨/텍스트. get_ui_tree 결과에서 확인한 텍스트를 사용하세요.")]),
            "index": .object(["type": .string("integer"), "description": .string("동일 라벨이 여러 개일 때 몇 번째 요소인지 지정 (0부터 시작). get_ui_tree에서 라벨#인덱스 형식으로 표시됩니다.")]),
            "duration": .object(["type": .string("number"), "description": .string("롱프레스 시간(초)")]),
            "app_bundle_id": .object(["type": .string("string"), "description": .string("앱 번들 ID")])
        ]),
        "required": .array([.string("label")])
    ])

    typealias Arguments = TapArgs

    static func execute(args: TapArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        var appBundleId = args.appBundleId
        if appBundleId == nil {
            appBundleId = try await client.foregroundApp().bundleId
        }

        let response = try await client.tree(appBundleId: appBundleId)
        guard let element = response.tree.findElement(byLabel: args.label, index: args.index) else {
            if let index = args.index {
                throw IOSControlError.elementNotFound("\(args.label)#\(index)")
            }
            throw IOSControlError.elementNotFound(args.label)
        }

        let center = element.frame.center
        try await client.tap(x: center.x, y: center.y, duration: args.duration)

        let labelDesc = args.index != nil ? "\"\(args.label)\"#\(args.index!)" : "\"\(args.label)\""
        if let duration = args.duration {
            return [.text("tapped \(labelDesc) at (\(center.x), \(center.y)) for \(duration)s")]
        }
        return [.text("tapped \(labelDesc) at (\(center.x), \(center.y))")]
    }
}
