import Foundation
import MCP
import Common
import IOSControlClient

struct DragTool: MCPTool {
    static let name = "drag"

    static let description = "라벨로 UI 요소를 찾아 드래그합니다. 리스트 항목 재정렬 시 Reorder 같은 드래그 핸들을 from_label로 선택하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "from_label": .object(["type": .string("string"), "description": .string("드래그할 요소의 라벨")]),
            "from_index": .object(["type": .string("integer"), "description": .string("동일 라벨이 여러 개일 때 인덱스 (0부터 시작)")]),
            "to_label": .object(["type": .string("string"), "description": .string("드롭할 위치의 요소 라벨")]),
            "to_index": .object(["type": .string("integer"), "description": .string("동일 라벨이 여러 개일 때 인덱스 (0부터 시작)")]),
            "duration": .object(["type": .string("number"), "description": .string("드래그 이동 시간(초). 기본값 0.3")]),
            "hold_duration": .object(["type": .string("number"), "description": .string("드래그 시작 전 홀드 시간(초). 기본값 0.5")])
        ]),
        "required": .array([.string("from_label"), .string("to_label")])
    ])

    typealias Arguments = DragArgs

    static func execute(args: DragArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let appBundleId = try await client.foregroundApp().bundleId
        let response = try await client.tree(appBundleId: appBundleId)

        // from 요소 찾기
        guard let fromElement = response.tree.findElement(byLabel: args.fromLabel, index: args.fromIndex) else {
            let label = args.fromIndex != nil ? "\(args.fromLabel)#\(args.fromIndex!)" : args.fromLabel
            throw IOSControlError.elementNotFound(label)
        }

        // to 요소 찾기
        guard let toElement = response.tree.findElement(byLabel: args.toLabel, index: args.toIndex) else {
            let label = args.toIndex != nil ? "\(args.toLabel)#\(args.toIndex!)" : args.toLabel
            throw IOSControlError.elementNotFound(label)
        }

        let fromCenter = fromElement.frame.center
        let toCenter = toElement.frame.center
        let duration = args.duration ?? GestureDefaults.dragDuration
        let holdDuration = args.holdDuration ?? GestureDefaults.holdDuration

        try await client.swipe(
            startX: fromCenter.x,
            startY: fromCenter.y,
            endX: toCenter.x,
            endY: toCenter.y,
            duration: duration,
            holdDuration: holdDuration,
            liftDelay: GestureDefaults.liftDelay
        )

        let fromDesc = args.fromIndex != nil ? "\"\(args.fromLabel)\"#\(args.fromIndex!)" : "\"\(args.fromLabel)\""
        let toDesc = args.toIndex != nil ? "\"\(args.toLabel)\"#\(args.toIndex!)" : "\"\(args.toLabel)\""
        return [.text("dragged \(fromDesc) to \(toDesc)")]
    }
}
