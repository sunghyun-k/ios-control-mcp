import Foundation
import iOSAutomation
import MCP

enum PressButtonTool: MCPToolDefinition {
    static let name = "press_button"
    static let description = "Press a hardware button on the device."
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "button",
            type: .string,
            description: "Button to press: home, volumeUp, volumeDown",
            enumValues: ["home", "volumeUp", "volumeDown"],
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let buttonStr = try args.string("button")
        guard let button = HardwareButton(rawValue: buttonStr) else {
            throw ToolError
                .invalidArgument(
                    "Invalid button: \(buttonStr). Must be home, volumeUp, or volumeDown.",
                )
        }

        try await automation.pressButton(button)
        return [.text("Pressed \(buttonStr) button")]
    }
}
