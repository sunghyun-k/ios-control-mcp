import Foundation
import MCP
import IOSControlClient

struct InputTextTool: MCPTool {
    static let name = "input_text"

    static let description = "텍스트를 입력합니다. 키보드가 활성화되어 있어야 합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "text": .object(["type": .string("string"), "description": .string("입력할 텍스트")])
        ]),
        "required": .array([.string("text")])
    ])

    typealias Arguments = InputTextArgs

    static func execute(args: InputTextArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        try await client.inputText(args.text)
        return [.text("typed \"\(args.text)\"")]
    }
}
