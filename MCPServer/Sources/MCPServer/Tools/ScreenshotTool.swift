import Foundation
import iOSAutomation
import MCP

enum ScreenshotTool: MCPToolDefinition {
    static let name = "screenshot"
    static let description = "Take a screenshot of the current screen. Returns PNG image data as base64."
    static let parameters: [ToolParameter] = []

    static func execute(
        arguments _: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let data = try await automation.screenshot()
        let base64 = data.base64EncodedString()
        return [.image(data: base64, mimeType: "image/png", metadata: nil)]
    }
}
