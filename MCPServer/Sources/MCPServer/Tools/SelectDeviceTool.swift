import Foundation
import MCP
import IOSControlClient

struct SelectDeviceTool: MCPTool {
    static let name = "select_device"

    static let description = "조작할 iOS 기기를 선택합니다. 실기기가 여러 대일 때 사용하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "udid": .object([
                "type": .string("string"),
                "description": .string("선택할 기기의 UDID. 생략하면 선택 해제 (자동 선택 모드)")
            ])
        ])
    ])

    typealias Arguments = SelectDeviceArgs

    static func execute(args: Arguments, client: any AgentClient) async throws -> [Tool.Content] {
        // udid가 없으면 선택 해제
        guard let udid = args.udid else {
            await DeviceManager.shared.clearSelection()
            return [.text("Device selection cleared. Auto-select mode enabled.")]
        }

        // 기기 선택 (싱글톤 사용)
        try await DeviceManager.shared.selectDevice(udid: udid)

        // 선택된 기기 정보 반환
        if let device = try await DeviceManager.shared.getCurrentDevice() {
            let typeStr = device.type == .simulator ? "Simulator" : "Physical Device"
            var message = "Selected: \(device.name) (\(typeStr))\n"
            message += "UDID: \(device.id)\n"
            if let os = device.osVersion {
                message += "iOS: \(os)"
            }
            return [.text(message)]
        }

        return [.text("Device selected: \(udid)")]
    }
}
