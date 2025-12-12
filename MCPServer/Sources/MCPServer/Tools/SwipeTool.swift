import Foundation
import iOSAutomation
import MCP

enum SwipeTool: MCPToolDefinition {
    static let name = "swipe"
    static let description = "Swipe in a direction. Optionally on a specific element."
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "direction",
            type: .string,
            description: "Swipe direction: up, down, left, right",
            enumValues: ["up", "down", "left", "right"],
        ),
        ToolParameter(
            name: "label",
            type: .string,
            description: "Optional: Label of element to swipe on",
            required: false,
        ),
        ToolParameter(
            name: "element_type",
            type: .string,
            description: "Optional: Filter by element type (e.g., scroll_view, table, collection_view)",
            required: false,
            enumValues: AXElementType.commonTypeNames,
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let directionStr = try args.string("direction")
        guard let direction = SwipeDirection(rawValue: directionStr) else {
            throw ToolError
                .invalidArgument(
                    "Invalid direction: \(directionStr). Must be up, down, left, or right.",
                )
        }
        let label = args.optionalString("label")
        let elementType = args.optionalString("element_type").flatMap { AXElementType(name: $0) }

        try await automation.swipeByLabel(
            direction: direction,
            label: label,
            elementType: elementType,
        )

        var message = "Swiped \(directionStr)"
        if let label {
            message += " on '\(label)'"
        }
        if let elementType {
            message += " (type: \(elementType.name))"
        }
        return [.text(message)]
    }
}
