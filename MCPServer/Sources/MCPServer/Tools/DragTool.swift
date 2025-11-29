import Foundation
import MCP
import Common
import IOSControlClient

struct DragTool: MCPTool {
    static let name = "drag"

    static let description = "Finds and drags a UI element by label. For list reordering, select a drag handle like Reorder as from_label."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "from_label": .object(["type": .string("string"), "description": .string("Label of the element to drag")]),
            "from_element_type": .object(["type": .string("string"), "description": .string("Element type to drag (e.g., Button, Cell)")]),
            "from_index": .object(["type": .string("integer"), "description": .string("Index when multiple elements have the same label (and type). 0-based")]),
            "to_label": .object(["type": .string("string"), "description": .string("Label of the element to drop onto")]),
            "to_element_type": .object(["type": .string("string"), "description": .string("Element type to drop onto (e.g., Button, Cell)")]),
            "to_index": .object(["type": .string("integer"), "description": .string("Index when multiple elements have the same label (and type). 0-based")]),
            "duration": .object(["type": .string("number"), "description": .string("Drag movement duration in seconds. Default 0.3")]),
            "hold_duration": .object(["type": .string("number"), "description": .string("Hold time before drag starts in seconds. Default 0.5")])
        ]),
        "required": .array([.string("from_label"), .string("to_label")])
    ])

    typealias Arguments = DragArgs

    static func execute(args: DragArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let appBundleId = try await client.foregroundApp().bundleId
        let response = try await client.tree(appBundleId: appBundleId)

        // from 요소 찾기
        guard let fromElement = response.tree.findElement(byLabel: args.fromLabel, type: args.fromElementType, index: args.fromIndex) else {
            throw IOSControlError.elementNotFound(formatElementQuery(label: args.fromLabel, type: args.fromElementType, index: args.fromIndex))
        }

        // to 요소 찾기
        guard let toElement = response.tree.findElement(byLabel: args.toLabel, type: args.toElementType, index: args.toIndex) else {
            throw IOSControlError.elementNotFound(formatElementQuery(label: args.toLabel, type: args.toElementType, index: args.toIndex))
        }

        let fromCenter = fromElement.frame.center
        let toCenter = toElement.frame.center
        let duration = args.duration ?? GestureDefaults.dragDuration
        let holdDuration = args.holdDuration ?? GestureDefaults.holdDuration

        try await client.swipe(
            startX: fromCenter.x,
            startY: fromCenter.y,
            endX: toCenter.x,
            endY: toCenter.y,
            duration: duration,
            holdDuration: holdDuration,
            liftDelay: GestureDefaults.liftDelay
        )

        let fromDesc = formatElementQuery(label: args.fromLabel, type: args.fromElementType, index: args.fromIndex)
        let toDesc = formatElementQuery(label: args.toLabel, type: args.toElementType, index: args.toIndex)
        return [.text("dragged \(fromDesc) to \(toDesc)")]
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
