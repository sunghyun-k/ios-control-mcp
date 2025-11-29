import Foundation
import MCP
import IOSControlClient

struct ScrollTool: MCPTool {
    static let name = "scroll"

    static let description = "화면을 스크롤합니다. down=아래 내용 보기(위로 스와이프), up=위 내용 보기(아래로 스와이프)"

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "direction": .object([
                "type": .string("string"),
                "enum": .array([.string("up"), .string("down")]),
                "description": .string("스크롤 방향. down=아래 내용 보기, up=위 내용 보기")
            ]),
            "distance": .object(["type": .string("number"), "description": .string("스크롤 거리(픽셀). 기본값 300")]),
            "start_x": .object(["type": .string("number"), "description": .string("시작 X 좌표")]),
            "start_y": .object(["type": .string("number"), "description": .string("시작 Y 좌표")])
        ]),
        "required": .array([.string("direction")])
    ])

    typealias Arguments = ScrollArgs

    static func execute(args: ScrollArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        let distance = args.distance ?? 300
        let response = try await client.tree()
        let frame = response.tree.frame

        let x = args.startX ?? (frame.width / 2)
        let y = args.startY ?? (frame.height / 2)

        // down = 아래 내용을 보고 싶다 = 위로 스와이프 (endY < startY)
        // up = 위 내용을 보고 싶다 = 아래로 스와이프 (endY > startY)
        let endY = args.direction == "down" ? y - distance : y + distance
        try await client.swipe(startX: x, startY: y, endX: x, endY: endY, duration: 0.3)

        return [.text("scrolled \(args.direction) \(distance)px")]
    }
}
