import Foundation
import MCP
import IOSControlClient

struct SelectDeviceTool: MCPTool {
    static let name = "select_device"

    static let description = "조작할 iOS 기기를 선택합니다. list_devices로 기기 목록을 확인한 후 UDID를 지정하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "udid": .object([
                "type": .string("string"),
                "description": .string("선택할 기기의 UDID. list_devices로 확인할 수 있습니다.")
            ])
        ]),
        "required": .array([.string("udid")])
    ])

    typealias Arguments = SelectDeviceArgs

    static func execute(args: Arguments, client: IOSControlClient) async throws -> [Tool.Content] {
        let deviceManager = DeviceManager()

        // 기기 선택
        try await deviceManager.selectDevice(udid: args.udid)

        // 선택된 기기 정보 반환
        if let device = try await deviceManager.getCurrentDevice() {
            let typeStr = device.type == .simulator ? "Simulator" : "Physical Device"
            var message = "Selected: \(device.name) (\(typeStr))\n"
            message += "UDID: \(device.id)\n"
            if let os = device.osVersion {
                message += "iOS: \(os)"
            }
            return [.text(message)]
        }

        return [.text("Device selected: \(args.udid)")]
    }
}
