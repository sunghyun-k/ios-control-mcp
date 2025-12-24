import Foundation
import iOSAutomation
import MCP

enum LongPressTool: MCPToolDefinition {
    static let name = "long_press"
    static let description =
        "Long press a UI element by its label. Use get_ui_snapshot to find available labels."
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "label",
            type: .string,
            description: "Label of the element to long press. Use exact text from get_ui_snapshot.",
        ),
        ToolParameter(
            name: "duration",
            type: .number,
            description: "Duration to hold the press in seconds (default: 1.0)",
            required: false,
        ),
        ToolParameter(
            name: "element_type",
            type: .string,
            description: "Optional: Filter by element type (e.g., button, static_text, text_field)",
            required: false,
            enumValues: AXElementType.commonTypeNames,
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let label = try args.string("label")
        let duration = args.optionalDouble("duration") ?? 1.0
        let elementType = args.optionalString("element_type").flatMap { AXElementType(name: $0) }

        try await automation.longPressByLabel(label, elementType: elementType, duration: duration)

        var message = "Long pressed '\(label)' for \(duration)s"
        if let elementType {
            message += " (type: \(elementType.name))"
        }

        let snapshots = try await automation.snapshot()
        let snapshotText = formatSnapshot(snapshots)
        return [.text("\(message)\n\n\(snapshotText)")]
    }
}
