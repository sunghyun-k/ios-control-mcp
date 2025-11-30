import Foundation
import MCP
import IOSControlClient

struct ListDevicesTool: MCPTool {
    static let name = "list_devices"

    static let description = "Returns a list of physical iOS devices connected via USB. Not needed when using simulators."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: Arguments, client: any AgentClient) async throws -> [Tool.Content] {
        let devices = try DeviceCtlRunner.shared.listDevices()

        if devices.isEmpty {
            return [.text("No physical devices connected.")]
        }

        var lines: [String] = ["## Connected Physical Devices"]
        for device in devices {
            lines.append("- \(device.name) (\(device.hardwareUdid))")
            if let os = device.osVersion {
                lines.append("  \(device.platform) \(os)")
            }
            lines.append("  Model: \(device.model)")
            lines.append("  Connection: \(device.transportType) (\(device.connectionState))")
        }

        return [.text(lines.joined(separator: "\n"))]
    }
}
