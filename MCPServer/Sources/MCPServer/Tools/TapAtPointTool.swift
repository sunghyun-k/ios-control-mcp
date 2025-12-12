import Foundation
import iOSAutomation
import MCP

enum TapAtPointTool: MCPToolDefinition {
    static let name = "tap_at_point"
    static let description = "Tap at specific screen coordinates."
    static let parameters: [ToolParameter] = [
        ToolParameter(name: "x", type: .number, description: "X coordinate"),
        ToolParameter(name: "y", type: .number, description: "Y coordinate"),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let x = try args.double("x")
        let y = try args.double("y")

        try await automation.tapAtPoint(x: x, y: y)
        return [.text("Tapped at (\(x), \(y))")]
    }
}
