import Foundation
import iOSAutomation
import MCP

enum TypeTextTool: MCPToolDefinition {
    static let name = "type_text"
    static let description =
        "Type text. If label is provided, focuses on that element first. Otherwise types at current focus."
    static let parameters: [ToolParameter] = [
        ToolParameter(name: "text", type: .string, description: "Text to type"),
        ToolParameter(
            name: "label",
            type: .string,
            description: "Optional: Label of text field to focus first",
            required: false,
        ),
        ToolParameter(
            name: "element_type",
            type: .string,
            description: "Optional: Filter by element type (e.g., text_field, search_field, secure_text_field)",
            required: false,
            enumValues: AXElementType.commonTypeNames,
        ),
        ToolParameter(
            name: "submit",
            type: .boolean,
            description: "Press return/enter after typing (default: false)",
            required: false,
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let text = try args.string("text")
        let label = args.optionalString("label")
        let elementType = args.optionalString("element_type").flatMap { AXElementType(name: $0) }
        let submit = args.bool("submit")

        try await automation.typeText(text, label: label, elementType: elementType, submit: submit)

        var message = "Typed '\(text)'"
        if let label {
            message += " in '\(label)'"
        }
        if let elementType {
            message += " (type: \(elementType.name))"
        }
        if submit {
            message += " and submitted"
        }

        let snapshots = try await automation.snapshot()
        let snapshotText = formatSnapshot(snapshots)
        return [.text("\(message)\n\n\(snapshotText)")]
    }
}
