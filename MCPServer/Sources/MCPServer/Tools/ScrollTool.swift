import Foundation
import MCP
import IOSControlClient

struct ScrollTool: MCPTool {
    static let name = "scroll"

    static let description = "화면을 스크롤합니다. down=아래 내용 보기, up=위 내용 보기"

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "direction": .object([
                "type": .string("string"),
                "enum": .array([.string("up"), .string("down")]),
                "description": .string("스크롤 방향. down=아래 내용 보기, up=위 내용 보기")
            ]),
            "distance": .object(["type": .string("number"), "description": .string("스크롤 거리(픽셀). 기본값 300")]),
            "duration": .object(["type": .string("number"), "description": .string("스크롤 시간(초). 기본값 0.3")]),
            "start_x": .object(["type": .string("number"), "description": .string("시작 X 좌표. 기본값은 화면 중앙")]),
            "start_y": .object(["type": .string("number"), "description": .string("시작 Y 좌표. 기본값은 화면 중앙")])
        ]),
        "required": .array([.string("direction")])
    ])

    typealias Arguments = ScrollArgs

    static func execute(args: ScrollArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let distance = args.distance ?? GestureDefaults.scrollDistance
        let duration = args.duration ?? GestureDefaults.scrollDuration
        let response = try await client.tree()
        let frame = response.tree.frame

        let x = args.startX ?? (frame.width / 2)
        let y = args.startY ?? (frame.height / 2)

        // down = 아래 내용을 보고 싶다 = 위로 스와이프 (endY < startY)
        // up = 위 내용을 보고 싶다 = 아래로 스와이프 (endY > startY)
        let endY = args.direction == "down" ? y - distance : y + distance
        try await client.swipe(startX: x, startY: y, endX: x, endY: endY, duration: duration, liftDelay: GestureDefaults.liftDelay)

        return [.text("scrolled \(args.direction) \(Int(distance))px")]
    }
}
