import Foundation
import MCP
import IOSControlClient

struct PinchTool: MCPTool {
    static let name = "pinch"

    static let description = "Performs a pinch gesture. scale > 1.0 zooms in, < 1.0 zooms out"

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "x": .object(["type": .string("number"), "description": .string("Pinch center X coordinate. Default is screen center")]),
            "y": .object(["type": .string("number"), "description": .string("Pinch center Y coordinate. Default is screen center")]),
            "scale": .object(["type": .string("number"), "description": .string("Zoom scale. Less than 1.0 zooms out, greater than 1.0 zooms in (e.g., 2.0 = 2x zoom)")]),
            "velocity": .object(["type": .string("number"), "description": .string("Pinch velocity. Default 1.0")])
        ]),
        "required": .array([.string("scale")])
    ])

    typealias Arguments = PinchArgs

    static func execute(args: PinchArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let response = try await client.tree()
        let frame = response.tree.frame

        let x = args.x ?? (frame.width / 2)
        let y = args.y ?? (frame.height / 2)
        let velocity = args.velocity ?? 1.0

        try await client.pinch(x: x, y: y, scale: args.scale, velocity: velocity)
        let action = args.scale > 1.0 ? "zoomed in" : "zoomed out"
        return [.text("\(action) at (\(x), \(y)) with scale \(args.scale)")]
    }
}
