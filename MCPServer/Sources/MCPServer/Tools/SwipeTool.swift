import Foundation
import MCP
import IOSControlClient

struct SwipeTool: MCPTool {
    static let name = "swipe"

    static let description = "Swipes from start point to end point. Use scroll for regular scrolling, drag for element dragging."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "start_x": .object(["type": .string("number"), "description": .string("Start X coordinate")]),
            "start_y": .object(["type": .string("number"), "description": .string("Start Y coordinate")]),
            "end_x": .object(["type": .string("number"), "description": .string("End X coordinate")]),
            "end_y": .object(["type": .string("number"), "description": .string("End Y coordinate")]),
            "duration": .object(["type": .string("number"), "description": .string("Swipe duration in seconds. Default 0.5")]),
            "hold_duration": .object(["type": .string("number"), "description": .string("Hold time before swipe starts in seconds. Used for dragging")])
        ]),
        "required": .array([.string("start_x"), .string("start_y"), .string("end_x"), .string("end_y")])
    ])

    typealias Arguments = SwipeArgs

    static func execute(args: SwipeArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let duration = args.duration ?? GestureDefaults.swipeDuration
        try await client.swipe(startX: args.startX, startY: args.startY, endX: args.endX, endY: args.endY, duration: duration, holdDuration: args.holdDuration, liftDelay: GestureDefaults.liftDelay)
        return [.text("swiped (\(args.startX), \(args.startY)) -> (\(args.endX), \(args.endY))")]
    }
}
