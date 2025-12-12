import Foundation
import iOSAutomation
import MCP

enum ListDevicesTool: MCPToolDefinition {
    static let name = "list_devices"
    static let description = """
    List all available iOS devices (simulators and physical devices).
    Returns device ID (UDID), name, type, and connection status.
    Use this to find a device before calling select_device.
    """
    static let parameters: [ToolParameter] = []

    static func execute(
        arguments _: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let devices = try automation.listDevices()

        if devices.isEmpty {
            return [.text("No devices found. Start a simulator or connect a physical device.")]
        }

        var lines = ["Available devices:"]
        for device in devices {
            let status = device.isConnected ? "connected" : "disconnected"
            let typeIcon = device.type == .physical ? "physical" : "simulator"
            let osInfo = device.osVersion.map { " (iOS \($0))" } ?? ""
            lines.append("- [\(typeIcon)] \(device.name)\(osInfo)")
            lines.append("  ID: \(device.id)")
            lines.append("  Status: \(status)")
        }

        // 현재 선택된 기기 표시
        if let selected = automation.selectedDevice {
            lines.append("")
            lines.append("Currently selected: \(selected.name) (\(selected.id))")
        }

        return [.text(lines.joined(separator: "\n"))]
    }
}
