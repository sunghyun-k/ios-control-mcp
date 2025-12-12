import Foundation
import iOSAutomation
import MCP

enum GetUISnapshotTool: MCPToolDefinition {
    static let name = "get_ui_snapshot"
    static let description = "Get UI element tree of all foreground apps. Returns hierarchical view of UI elements with labels, types, and structure."
    static let parameters: [ToolParameter] = []

    static func execute(
        arguments _: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let snapshots = try await automation.snapshot()

        var result = ""
        for (bundleId, element) in snapshots.sorted(by: { $0.key < $1.key }) {
            result += "[\(bundleId)]\n"
            result += element.toYAML()
            result += "\n\n"
        }

        return [.text(result.trimmingCharacters(in: .whitespacesAndNewlines))]
    }
}
