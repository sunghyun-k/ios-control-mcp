import Foundation
import MCP
import IOSControlClient

struct TapCoordinateTool: MCPTool {
    static let name = "tap_coordinate"

    static let description = "iOS 시뮬레이터 화면의 특정 좌표를 탭합니다. 라벨로 요소를 찾을 수 없는 경우에만 사용하세요. 일반적인 경우 tap 도구를 우선 사용하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "x": .object(["type": .string("number"), "description": .string("X 좌표")]),
            "y": .object(["type": .string("number"), "description": .string("Y 좌표")]),
            "duration": .object(["type": .string("number"), "description": .string("롱프레스 시간(초)")])
        ]),
        "required": .array([.string("x"), .string("y")])
    ])

    typealias Arguments = TapCoordinateArgs

    static func execute(args: TapCoordinateArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        try await client.tap(x: args.x, y: args.y, duration: args.duration)

        if let duration = args.duration {
            return [.text("tapped (\(args.x), \(args.y)) for \(duration)s")]
        }
        return [.text("tapped (\(args.x), \(args.y))")]
    }
}
