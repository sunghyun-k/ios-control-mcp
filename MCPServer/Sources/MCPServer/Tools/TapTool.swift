import Foundation
import iOSAutomation
import MCP

enum TapTool: MCPToolDefinition {
    static let name = "tap"
    static let description = "Tap a UI element by its label. Use get_ui_snapshot to find available labels."
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "label",
            type: .string,
            description: "Label of the element to tap. Use exact text from get_ui_snapshot.",
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
        let elementType = args.optionalString("element_type").flatMap { AXElementType(name: $0) }

        try await automation.tapByLabel(label, elementType: elementType)

        var message = "Tapped '\(label)'"
        if let elementType {
            message += " (type: \(elementType.name))"
        }
        return [.text(message)]
    }
}
