import Foundation
import MCP

let server = await Server(
    name: "ios-control",
    version: appVersion,
    capabilities: .init(tools: .init())
)
.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: ToolRegistry.allTools)
}
.withMethodHandler(CallTool.self) { params in
    do {
        let content = try await ToolRegistry.handle(name: params.name, arguments: params.arguments)
        return CallTool.Result(content: content)
    } catch {
        return CallTool.Result(content: [.text("Error: \(error.localizedDescription)")], isError: true)
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)

await server.waitUntilCompleted()
