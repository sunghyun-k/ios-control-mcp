import Foundation
import iOSAutomation
import MCP

enum DragTool: MCPToolDefinition {
    static let name = "drag"
    static let description = "Drag from one element to another by their labels."
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "source_label",
            type: .string,
            description: "Label of element to drag from",
        ),
        ToolParameter(
            name: "target_label",
            type: .string,
            description: "Label of element to drag to",
        ),
        ToolParameter(
            name: "source_element_type",
            type: .string,
            description: "Optional: Filter source by element type",
            required: false,
            enumValues: AXElementType.commonTypeNames,
        ),
        ToolParameter(
            name: "target_element_type",
            type: .string,
            description: "Optional: Filter target by element type",
            required: false,
            enumValues: AXElementType.commonTypeNames,
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let sourceLabel = try args.string("source_label")
        let targetLabel = try args.string("target_label")
        let sourceElementType = args.optionalString("source_element_type")
            .flatMap { AXElementType(name: $0) }
        let targetElementType = args.optionalString("target_element_type")
            .flatMap { AXElementType(name: $0) }

        try await automation.dragByLabel(
            sourceLabel: sourceLabel,
            targetLabel: targetLabel,
            sourceElementType: sourceElementType,
            targetElementType: targetElementType,
        )

        let message = "Dragged from '\(sourceLabel)' to '\(targetLabel)'"
        let snapshots = try await automation.snapshot()
        let snapshotText = formatSnapshot(snapshots)
        return [.text("\(message)\n\n\(snapshotText)")]
    }
}
