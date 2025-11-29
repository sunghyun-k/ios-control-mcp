import Foundation
import MCP
import IOSControlClient

struct InputTextTool: MCPTool {
    static let name = "input_text"

    static let description = "Inputs text. Keyboard must be active."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "text": .object(["type": .string("string"), "description": .string("Text to input")])
        ]),
        "required": .array([.string("text")])
    ])

    typealias Arguments = InputTextArgs

    static func execute(args: InputTextArgs, client: any AgentClient) async throws -> [Tool.Content] {
        try await client.inputText(args.text)
        return [.text("typed \"\(args.text)\"")]
    }
}
