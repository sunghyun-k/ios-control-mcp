# ios-control-mcp

[![npm version](https://img.shields.io/npm/v/ios-control-mcp)](https://www.npmjs.com/package/ios-control-mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

[한국어](README.ko.md)

An MCP (Model Context Protocol) server for automating iOS simulators and real iOS devices. Enables LLMs like Claude to interact with iOS devices.

https://github.com/user-attachments/assets/4284357b-6b6e-4e6a-a81c-e5976052be51

## Quick Start

Get started in 30 seconds:

1. Add to your MCP client config:
   ```json
   {
     "mcpServers": {
       "ios-control": {
         "command": "npx",
         "args": ["-y", "ios-control-mcp"]
       }
     }
   }
   ```

2. Ask Claude: *"Take a screenshot of the iOS simulator"*

That's it! Claude can now control iOS simulators. See [Installation](#installation) for detailed setup instructions.

## Features

### Device Management

- **list_devices** - List connected iOS devices (simulators and physical devices)
- **select_device** - Select device to control by UDID

### Screen Information

- **get_ui_snapshot** - Get UI element tree of all foreground apps
- **screenshot** - Take a screenshot of the current screen

### UI Interactions

- **tap** - Tap a UI element by its label
- **type_text** - Type text (optionally into a specific element)
- **swipe** - Swipe in a direction
- **drag** - Drag from one element to another by their labels

### App & Device Control

- **launch_app** - Launch an app by its bundle ID
- **press_button** - Press a hardware button (home, volumeUp, volumeDown)

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

For physical devices, add the Team ID environment variable:

```bash
claude mcp add ios-control -e IOS_CONTROL_TEAM_ID=YOUR_TEAM_ID -- npx -y ios-control-mcp
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

## Usage Examples

Here are some things you can ask Claude:

**Screenshots & UI inspection:**
> "Take a screenshot of the current screen"
> "Show me the UI snapshot"

**App navigation:**
> "Open the Settings app"
> "Launch Safari"

**UI interactions:**
> "Tap the 'Sign In' button"
> "Type 'hello@example.com' in the email field"
> "Swipe up"

## License

MIT
