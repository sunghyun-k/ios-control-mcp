import Foundation
import MCP

let server = await Server(
    name: "ios-control",
    version: appVersion,
    capabilities: .init(tools: .init())
)
.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: Tools.all)
}
.withMethodHandler(CallTool.self) { params in
    do {
        let content = try await ToolHandler.handle(name: params.name, arguments: params.arguments)
        return CallTool.Result(content: content)
    } catch {
        return CallTool.Result(content: [.text("Error: \(error.localizedDescription)")], isError: true)
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)

await server.waitUntilCompleted()
