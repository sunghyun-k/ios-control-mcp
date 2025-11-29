import Foundation
import MCP
import IOSControlClient

struct SwipeTool: MCPTool {
    static let name = "swipe"

    static let description = "좌표 기반 스와이프를 수행합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "start_x": .object(["type": .string("number"), "description": .string("시작 X 좌표")]),
            "start_y": .object(["type": .string("number"), "description": .string("시작 Y 좌표")]),
            "end_x": .object(["type": .string("number"), "description": .string("끝 X 좌표")]),
            "end_y": .object(["type": .string("number"), "description": .string("끝 Y 좌표")]),
            "duration": .object(["type": .string("number"), "description": .string("스와이프 시간(초). 기본값 0.5")]),
            "hold_duration": .object(["type": .string("number"), "description": .string("터치 후 스와이프 시작 전 대기 시간(초). 드래그 시 사용")])
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
