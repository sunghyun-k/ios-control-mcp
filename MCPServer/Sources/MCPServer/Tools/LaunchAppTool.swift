import Foundation
import iOSAutomation
import MCP

enum LaunchAppTool: MCPToolDefinition {
    static let name = "launch_app"
    static let description = "Launch an app by its bundle ID."
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "bundle_id",
            type: .string,
            description: "Bundle ID of the app (e.g., com.apple.Preferences for Settings)",
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let bundleId = try args.string("bundle_id")

        try await automation.launchApp(bundleId: bundleId)
        return [.text("Launched '\(bundleId)'")]
    }
}
