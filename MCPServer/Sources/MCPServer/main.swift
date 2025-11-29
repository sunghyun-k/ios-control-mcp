import Foundation
import MCP

let instructions = """
Tools for automating iOS simulators and real devices.

## Basic Flow
1. Use get_ui_tree to check UI elements on the current screen
2. Interact using tap, input_text, etc.
3. Use screenshot to verify results if needed

## Tips
- Simulators are auto-selected. list_devices and select_device are only needed when multiple physical devices are connected.
- When the keyboard is open, elements may be hidden. Tap above the keyboard or scroll to dismiss it, then call get_ui_tree.
- If tap can't find an element, verify the label in get_ui_tree, or use show_coords: true to get coordinates and use tap_coordinate instead.
"""

let server = await Server(
    name: "ios-control",
    version: appVersion,
    instructions: instructions,
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
