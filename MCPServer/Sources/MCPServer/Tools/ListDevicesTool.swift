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
        let physicalDevices = try await DeviceManager.shared.listPhysicalDevices()

        if physicalDevices.isEmpty {
            return [.text("No physical devices connected.")]
        }

        var lines: [String] = ["## Connected Physical Devices"]
        for device in physicalDevices {
            lines.append("- \(device.name) (\(device.id))")
            if let os = device.osVersion {
                lines.append("  iOS \(os)")
            }
        }

        return [.text(lines.joined(separator: "\n"))]
    }
}
