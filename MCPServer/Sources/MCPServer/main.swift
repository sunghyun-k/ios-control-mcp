import Foundation
import iOSAutomation
import MCP

let instructions = """
iOS simulator/device automation tool.

## Basic Flow
1. Use get_ui_snapshot to check current screen UI elements
2. Interact with tap, type_text, etc.
3. Use get_ui_snapshot to verify results (use screenshot if unclear)
"""

let server = await Server(
    name: "ios-control",
    version: appVersion,
    instructions: instructions,
    capabilities: .init(tools: .init()),
)
.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: ToolRegistry.allTools)
}
.withMethodHandler(CallTool.self) { params in
    do {
        let content = try await ToolRegistry.handle(name: params.name, arguments: params.arguments)
        return CallTool.Result(content: content)
    } catch {
        return CallTool.Result(
            content: [.text("Error: \(error.localizedDescription)")],
            isError: true,
        )
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)

await server.waitUntilCompleted()
