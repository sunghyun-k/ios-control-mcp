import Foundation
import MCP
import IOSControlClient

struct PinchTool: MCPTool {
    static let name = "pinch"

    static let description = "핀치 제스처를 수행합니다. 지도나 이미지 확대/축소에 사용합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "x": .object(["type": .string("number"), "description": .string("핀치 중심 X 좌표")]),
            "y": .object(["type": .string("number"), "description": .string("핀치 중심 Y 좌표")]),
            "scale": .object(["type": .string("number"), "description": .string("줌 배율. 1.0 미만이면 줌 아웃, 1.0 초과면 줌 인 (예: 2.0은 2배 확대)")]),
            "velocity": .object(["type": .string("number"), "description": .string("핀치 속도. 기본값 1.0")])
        ]),
        "required": .array([.string("x"), .string("y"), .string("scale")])
    ])

    typealias Arguments = PinchArgs

    static func execute(args: PinchArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        let velocity = args.velocity ?? 1.0
        try await client.pinch(x: args.x, y: args.y, scale: args.scale, velocity: velocity)
        let action = args.scale > 1.0 ? "zoomed in" : "zoomed out"
        return [.text("\(action) at (\(args.x), \(args.y)) with scale \(args.scale)")]
    }
}
