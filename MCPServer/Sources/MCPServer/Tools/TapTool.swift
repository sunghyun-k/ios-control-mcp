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
            "element_type": .object(["type": .string("string"), "description": .string("요소 타입 (예: Button, TextField, StaticText). get_ui_tree에서 확인할 수 있습니다. 동일 라벨의 요소가 여러 타입으로 존재할 때 특정 타입만 찾을 수 있습니다.")]),
            "index": .object(["type": .string("integer"), "description": .string("동일 라벨(및 타입)이 여러 개일 때 몇 번째 요소인지 지정 (0부터 시작). get_ui_tree에서 라벨#인덱스 형식으로 표시됩니다.")]),
            "duration": .object(["type": .string("number"), "description": .string("롱프레스 시간(초)")])
        ]),
        "required": .array([.string("label")])
    ])

    typealias Arguments = TapArgs

    static func execute(args: TapArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let appBundleId = try await client.foregroundApp().bundleId
        let response = try await client.tree(appBundleId: appBundleId)
        guard let element = response.tree.findElement(byLabel: args.label, type: args.elementType, index: args.index) else {
            throw IOSControlError.elementNotFound(formatElementQuery(label: args.label, type: args.elementType, index: args.index))
        }

        let center = element.frame.center
        try await client.tap(x: center.x, y: center.y, duration: args.duration)

        let labelDesc = formatElementQuery(label: args.label, type: args.elementType, index: args.index)
        if let duration = args.duration {
            return [.text("tapped \(labelDesc) at (\(center.x), \(center.y)) for \(duration)s")]
        }
        return [.text("tapped \(labelDesc) at (\(center.x), \(center.y))")]
    }

    private static func formatElementQuery(label: String, type: String?, index: Int?) -> String {
        var result = "\"\(label)\""
        if let type = type {
            result = "[\(type)] \(result)"
        }
        if let index = index {
            result += "#\(index)"
        }
        return result
    }
}
