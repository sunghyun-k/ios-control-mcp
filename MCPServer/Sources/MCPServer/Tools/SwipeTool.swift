import Foundation
import MCP
import IOSControlClient

struct SwipeTool: MCPTool {
    static let name = "swipe"

    static let description = "Swipes from start point to end point. Use scroll for regular scrolling, drag for element dragging."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "start": .object(["type": .string("string"), "description": .string("Start coordinate as 'x,y' (e.g., '100,200')")]),
            "end": .object(["type": .string("string"), "description": .string("End coordinate as 'x,y' (e.g., '100,500')")]),
            "duration": .object(["type": .string("number"), "description": .string("Swipe duration in seconds. Default 0.5")]),
            "hold_duration": .object(["type": .string("number"), "description": .string("Hold time before swipe starts in seconds. Used for dragging")])
        ]),
        "required": .array([.string("start"), .string("end")])
    ])

    typealias Arguments = SwipeArgs

    static func execute(args: SwipeArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let startCoord = try args.parseStart()
        let endCoord = try args.parseEnd()
        let duration = args.duration ?? GestureDefaults.swipeDuration
        try await client.swipe(startX: startCoord.x, startY: startCoord.y, endX: endCoord.x, endY: endCoord.y, duration: duration, holdDuration: args.holdDuration, liftDelay: GestureDefaults.liftDelay)
        return [.text("swiped (\(startCoord.x), \(startCoord.y)) -> (\(endCoord.x), \(endCoord.y))")]
    }
}
