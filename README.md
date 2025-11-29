# ios-control-mcp

[한국어](README.ko.md)

An MCP (Model Context Protocol) server for automating iOS simulators and real iOS devices. Enables LLMs like Claude to interact with iOS devices.

## Features

### Device Management
- **list_devices** - List connected iOS devices (only needed when physical devices are connected)
- **select_device** - Select device to control (specify UDID or auto-select)

### UI Interactions
- **tap** - Find and tap UI element by label (supports long press)
- **tap_coordinate** - Tap at specific coordinates
- **swipe** - Swipe gesture
- **scroll** - Scroll screen (direction-based)
- **drag** - Drag UI element (for list reordering, etc.)
- **pinch** - Pinch zoom in/out (for maps, images)
- **input_text** - Input text

### App Management
- **launch_app** - Launch app by bundle ID
- **list_apps** - List installed apps
- **go_home** - Go to home screen

### Screen Information
- **get_ui_tree** - Get UI accessibility tree (YAML format, optional coordinates)
- **screenshot** - Capture screenshot (PNG)

## Requirements

- macOS 13 or later
- Xcode (with iOS Simulator)
- Node.js 18 or later
- For physical devices: Apple Developer Team ID (free or paid)

## Installation

### Using Simulator (Default)

Simulators work out of the box without additional setup.

**Standard config** - Works with most MCP clients:

```json
{
  "mcpServers": {
    "ios-control": {
      "command": "npx",
      "args": [
        "-y",
        "ios-control-mcp"
      ]
    }
  }
}
```

<details>
<summary>Claude Code</summary>

```bash
claude mcp add ios-control -- npx -y ios-control-mcp
```

</details>

<details>
<summary>Claude Desktop</summary>

Follow the [MCP installation guide](https://modelcontextprotocol.io/quickstart/user) using the standard config above.

</details>

<details>
<summary>Cursor</summary>

Go to `Cursor Settings` → `MCP` → `Add new MCP Server`. Set a name and enter `npx -y ios-control-mcp` as the command type.

</details>

<details>
<summary>VS Code</summary>

Install via VS Code CLI:

```bash
code --add-mcp '{"name":"ios-control","command":"npx","args":["-y","ios-control-mcp"]}'
```

Or follow the [MCP installation guide](https://code.visualstudio.com/docs/copilot/chat/mcp-servers#_add-an-mcp-server) using the standard config above.

</details>

<details>
<summary>Windsurf</summary>

Follow the [Windsurf MCP documentation](https://docs.windsurf.com/windsurf/cascade/mcp) using the standard config above.

</details>

### Using Physical iOS Devices

Using physical iOS devices requires an Apple Developer Team ID. A free Apple ID works too.

#### 1. Find Your Team ID

Run this command in Terminal to find your Team ID:

```bash
security find-identity -v -p codesigning
```

Example output:
```
1) ABCDEF1234567890... "Apple Development: your@email.com (XXXXXXXXXX)"
```

The 10-character string in parentheses (e.g., `XXXXXXXXXX`) is your Team ID.

> **Don't have a Team ID?** Open any project in Xcode, sign in with your Apple ID, and build to a device once. This will automatically generate a Team ID.

#### 2. Add Team ID to MCP Configuration

```json
{
  "mcpServers": {
    "ios-control": {
      "command": "npx",
      "args": ["-y", "ios-control-mcp"],
      "env": {
        "IOS_CONTROL_TEAM_ID": "YOUR_TEAM_ID"
      }
    }
  }
}
```

#### 3. Prepare Your Device

1. **Enable Developer Mode**: Settings → Privacy & Security → Developer Mode → Enable (iOS 16+)
2. **Connect via USB**: Connect your device to Mac via USB and tap "Trust" when prompted
3. **First run**: After the app is installed, if you see "Untrusted Developer" warning, go to Settings → General → VPN & Device Management and trust the developer app

## Troubleshooting

### Simulator

| Error | Solution |
|-------|----------|
| "No available iPhone simulator" | Install Xcode and run `xcodebuild -downloadPlatform iOS` |
| "AutomationServer app not found" | It builds automatically on first run. Make sure Xcode is installed. |
| "Simulator boot failed" | Check if iOS Simulator is installed in Xcode → Settings → Platforms |

### Physical Devices

| Error | Solution |
|-------|----------|
| "Physical device requires Apple Developer Team ID" | Add `IOS_CONTROL_TEAM_ID` to `env` in MCP config |
| "Xcode project not found" | Make sure Xcode is installed |
| Build failed (signing error) | 1) Verify Team ID is correct<br>2) Ensure device is connected via USB<br>3) Build any app to the device in Xcode first to set up provisioning |
| "Untrusted Developer" | Go to Settings → General → VPN & Device Management on device and trust the developer app |
| Device not showing in list | 1) Reconnect USB cable<br>2) Check "Trust This Computer" prompt<br>3) Verify Developer Mode is enabled |

### Common

| Error | Solution |
|-------|----------|
| "No iOS device or simulator available" | Install Xcode and download simulator, or connect a physical device via USB |
| "Server did not start" | Check if agent app is running properly on device/simulator. Retry or reboot the device. |

## Architecture

This project consists of two main components:

1. **MCP Server** (macOS) - MCP protocol server that communicates with LLMs
2. **AutomationServer** (iOS) - XCTest-based automation agent running on simulator/device

```
┌─────────────┐     MCP      ┌─────────────┐    HTTP     ┌──────────────────┐
│     LLM     │◄────────────►│  MCP Server │◄───────────►│ AutomationServer │
│  (Claude)   │   Protocol   │   (macOS)   │  (localhost)│    (iOS XCTest)  │
└─────────────┘              └─────────────┘             └──────────────────┘
```

It leverages the special privileges of the XCTest framework to run an HTTP server inside the simulator, synthesizing touch/swipe events through Objective-C runtime reflection.

## Development

### Build Commands

```bash
# MCP Server
make mcp              # Build
make mcp-run          # Build and run

# AutomationServer (Simulator)
make agent            # Build
make agent-run        # Build and run

# AutomationServer (Physical Device)
make device-agent TEAM=<TEAM_ID>
make device-agent-run DEVICE_UDID=<UDID> TEAM=<TEAM_ID>

# Test Playground
make playground

# Clean
make clean
```

### Playground

Test the client library directly without the MCP server:

1. Run AutomationServer (in separate terminal): `make agent-run`
2. Run Playground: `make playground`

Edit `MCPServer/Sources/Playground/main.swift` to write test code.

## License

MIT
