import Foundation
import MCP
import IOSControlClient

struct TapCoordinateTool: MCPTool {
    static let name = "tap_coordinate"

    static let description = "Taps at specific coordinates. Use when tap cannot find the element."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "coordinate": .object(["type": .string("string"), "description": .string("Tap coordinate as 'x,y' (e.g., '100,200')")]),
            "duration": .object(["type": .string("number"), "description": .string("Long press duration in seconds")])
        ]),
        "required": .array([.string("coordinate")])
    ])

    typealias Arguments = TapCoordinateArgs

    static func execute(args: TapCoordinateArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let coord = try args.parseCoordinate()
        try await client.tap(x: coord.x, y: coord.y, duration: args.duration)

        if let duration = args.duration {
            return [.text("tapped (\(coord.x), \(coord.y)) for \(duration)s")]
        }
        return [.text("tapped (\(coord.x), \(coord.y))")]
    }
}
