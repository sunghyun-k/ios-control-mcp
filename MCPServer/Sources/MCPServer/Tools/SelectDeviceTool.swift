import Foundation
import iOSAutomation
import MCP

enum SelectDeviceTool: MCPToolDefinition {
    static let name = "select_device"
    static let description = """
    Select an iOS device to use for subsequent commands.
    You must call list_devices first to find available device IDs.
    All other tools require a device to be selected first.
    """
    static let parameters: [ToolParameter] = [
        ToolParameter(
            name: "device_id",
            type: .string,
            description: "Device UDID from list_devices output",
        ),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let deviceId = try args.string("device_id")

        try await automation.selectDevice(udid: deviceId)

        guard let device = automation.selectedDevice else {
            return [.text("Device selected but could not retrieve device info.")]
        }

        let typeStr = device.type == .physical ? "physical device" : "simulator"
        return [.text("Selected \(typeStr): \(device.name) (\(device.id))")]
    }
}
