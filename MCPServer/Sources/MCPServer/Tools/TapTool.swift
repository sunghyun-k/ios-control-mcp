import Foundation
import MCP
import Common
import IOSControlClient

struct TapTool: MCPTool {
    static let name = "tap"

    static let description = "Finds and taps a UI element by label."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "label": .object(["type": .string("string"), "description": .string("Label/text of the element to find. Use text from get_ui_tree results.")]),
            "element_type": .object(["type": .string("string"), "description": .string("Element type (e.g., Button, TextField, StaticText). Check get_ui_tree for available types. Use to filter when same label exists across multiple types.")]),
            "index": .object(["type": .string("integer"), "description": .string("Index when multiple elements have the same label (and type). 0-based. Shown as label#index in get_ui_tree.")]),
            "duration": .object(["type": .string("number"), "description": .string("Long press duration in seconds")])
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
