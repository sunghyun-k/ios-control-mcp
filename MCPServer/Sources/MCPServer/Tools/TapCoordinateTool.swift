import Foundation
import MCP
import IOSControlClient

struct TapCoordinateTool: MCPTool {
    static let name = "tap_coordinate"

    static let description = "Taps at specific coordinates. Use when tap cannot find the element."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "x": .object(["type": .string("number"), "description": .string("X coordinate")]),
            "y": .object(["type": .string("number"), "description": .string("Y coordinate")]),
            "duration": .object(["type": .string("number"), "description": .string("Long press duration in seconds")])
        ]),
        "required": .array([.string("x"), .string("y")])
    ])

    typealias Arguments = TapCoordinateArgs

    static func execute(args: TapCoordinateArgs, client: any AgentClient) async throws -> [Tool.Content] {
        try await client.tap(x: args.x, y: args.y, duration: args.duration)

        if let duration = args.duration {
            return [.text("tapped (\(args.x), \(args.y)) for \(duration)s")]
        }
        return [.text("tapped (\(args.x), \(args.y))")]
    }
}
