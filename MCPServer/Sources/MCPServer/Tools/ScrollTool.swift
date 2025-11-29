import Foundation
import MCP
import IOSControlClient

struct ScrollTool: MCPTool {
    static let name = "scroll"

    static let description = "Scrolls the screen. down=view content below, up=view content above"

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "direction": .object([
                "type": .string("string"),
                "enum": .array([.string("up"), .string("down")]),
                "description": .string("Scroll direction. down=view content below, up=view content above")
            ]),
            "distance": .object(["type": .string("number"), "description": .string("Scroll distance in pixels. Default 300")]),
            "duration": .object(["type": .string("number"), "description": .string("Scroll duration in seconds. Default 0.3")]),
            "start": .object(["type": .string("string"), "description": .string("Start coordinate as 'x,y' (e.g., '200,400'). Default is screen center")])
        ]),
        "required": .array([.string("direction")])
    ])

    typealias Arguments = ScrollArgs

    static func execute(args: ScrollArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let distance = args.distance ?? GestureDefaults.scrollDistance
        let duration = args.duration ?? GestureDefaults.scrollDuration
        let response = try await client.tree()
        let frame = response.tree.frame

        let startCoord = args.parseStart()
        let x = startCoord?.x ?? (frame.width / 2)
        let y = startCoord?.y ?? (frame.height / 2)

        // down = 아래 내용을 보고 싶다 = 위로 스와이프 (endY < startY)
        // up = 위 내용을 보고 싶다 = 아래로 스와이프 (endY > startY)
        let endY = args.direction == "down" ? y - distance : y + distance
        try await client.swipe(startX: x, startY: y, endX: x, endY: endY, duration: duration, liftDelay: GestureDefaults.liftDelay)

        return [.text("scrolled \(args.direction) \(Int(distance))px")]
    }
}
