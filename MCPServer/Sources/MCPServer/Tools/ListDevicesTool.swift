import Foundation
import MCP
import IOSControlClient

struct ListDevicesTool: MCPTool {
    static let name = "list_devices"

    static let description = "연결된 모든 iOS 기기 목록을 반환합니다. 시뮬레이터와 USB로 연결된 실제 기기를 모두 포함합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "type": .object([
                "type": .string("string"),
                "description": .string("필터링할 기기 타입: 'simulator', 'physical', 또는 'all' (기본값)"),
                "enum": .array([.string("all"), .string("simulator"), .string("physical")])
            ])
        ])
    ])

    typealias Arguments = ListDevicesArgs

    static func execute(args: Arguments, client: IOSControlClient) async throws -> [Tool.Content] {
        let deviceManager = DeviceManager()
        let allDevices = try await deviceManager.listAllDevices()

        // 타입 필터링
        let filteredDevices: [DeviceInfo]
        switch args.type {
        case "simulator":
            filteredDevices = allDevices.filter { $0.type == .simulator }
        case "physical":
            filteredDevices = allDevices.filter { $0.type == .physical }
        default:
            filteredDevices = allDevices
        }

        // 결과 포맷팅
        var lines: [String] = []

        // 부팅된 시뮬레이터 먼저
        let booted = filteredDevices.filter { $0.type == .simulator && $0.isConnected }
        if !booted.isEmpty {
            lines.append("## Booted Simulators")
            for device in booted {
                lines.append("- \(device.name) (\(device.id))")
                if let os = device.osVersion {
                    lines.append("  iOS \(os)")
                }
            }
            lines.append("")
        }

        // 연결된 실기기
        let physical = filteredDevices.filter { $0.type == .physical && $0.isConnected }
        if !physical.isEmpty {
            lines.append("## Connected Physical Devices")
            for device in physical {
                lines.append("- \(device.name) (\(device.id))")
                if let os = device.osVersion {
                    lines.append("  iOS \(os)")
                }
            }
            lines.append("")
        }

        // 사용 가능한 시뮬레이터 (부팅되지 않은)
        let available = filteredDevices.filter { $0.type == .simulator && !$0.isConnected }
        if !available.isEmpty {
            lines.append("## Available Simulators (not booted)")
            for device in available.prefix(10) {  // 최대 10개만 표시
                lines.append("- \(device.name) (\(device.id))")
                if let os = device.osVersion {
                    lines.append("  iOS \(os)")
                }
            }
            if available.count > 10 {
                lines.append("... and \(available.count - 10) more")
            }
        }

        if lines.isEmpty {
            return [.text("No devices found.")]
        }

        return [.text(lines.joined(separator: "\n"))]
    }
}
