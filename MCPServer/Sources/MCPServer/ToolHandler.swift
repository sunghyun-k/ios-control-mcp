import Foundation
import MCP
import Common
import IOSControlClient

// MARK: - Tool Handler

enum ToolHandler {
    static func getDouble(_ value: Value?) -> Double? {
        guard let value = value else { return nil }
        if let d = value.doubleValue { return d }
        if let i = value.intValue { return Double(i) }
        return nil
    }

    static func handle(name: String, arguments: [String: Value]?) async throws -> [Tool.Content] {
        let client = IOSControlClient()
        let args = arguments ?? [:]

        // Agent 서버 필요한 도구들
        try await ensureServerRunning(client: client)

        switch name {
        case "tap":
            return try await handleTapElement(client: client, args: args)

        case "list_apps":
            return try await handleListApps(client: client)

        case "tap_coordinate":
            return try await handleTapCoordinate(client: client, args: args)

        case "swipe":
            return try await handleSwipe(client: client, args: args)

        case "scroll":
            return try await handleScroll(client: client, args: args)

        case "input_text":
            return try await handleInputText(client: client, args: args)

        case "get_ui_tree":
            return try await handleGetUITree(client: client, args: args)

        case "get_foreground_app":
            return try await handleGetForegroundApp(client: client)

        case "screenshot":
            return try await handleScreenshot(client: client)

        case "launch_app":
            return try await handleLaunchApp(client: client, args: args)

        case "go_home":
            return try await handleGoHome(client: client)

        case "terminate_app":
            return try await handleTerminateApp(client: client, args: args)

        case "open_url":
            return try await handleOpenURL(client: client, args: args)

        case "get_pasteboard":
            return try await handleGetPasteboard(client: client)

        case "set_pasteboard":
            return try await handleSetPasteboard(client: client, args: args)

        case "pinch":
            return try await handlePinch(client: client, args: args)

        default:
            throw IOSControlError.invalidResponse
        }
    }

    // MARK: - Individual Handlers

    private static func handleTapCoordinate(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let x = getDouble(args["x"]), let y = getDouble(args["y"]) else {
            throw IOSControlError.invalidResponse
        }
        let duration = getDouble(args["duration"])
        try await client.tap(x: x, y: y, duration: duration)

        if let duration = duration {
            return [.text("tapped (\(x), \(y)) for \(duration)s")]
        }
        return [.text("tapped (\(x), \(y))")]
    }

    private static func handleTapElement(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let label = args["label"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }
        let index = args["index"]?.intValue
        let duration = getDouble(args["duration"])
        var appBundleId = args["app_bundle_id"]?.stringValue
        if appBundleId == nil {
            appBundleId = try await client.foregroundApp().bundleId
        }

        let response = try await client.tree(appBundleId: appBundleId)
        guard let element = response.tree.findElement(byLabel: label, index: index) else {
            if let index = index {
                throw IOSControlError.elementNotFound("\(label)#\(index)")
            }
            throw IOSControlError.elementNotFound(label)
        }

        let center = element.frame.center
        try await client.tap(x: center.x, y: center.y, duration: duration)

        let labelDesc = index != nil ? "\"\(label)\"#\(index!)" : "\"\(label)\""
        if let duration = duration {
            return [.text("tapped \(labelDesc) at (\(center.x), \(center.y)) for \(duration)s")]
        }
        return [.text("tapped \(labelDesc) at (\(center.x), \(center.y))")]
    }

    private static func handleSwipe(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let startX = getDouble(args["start_x"]),
              let startY = getDouble(args["start_y"]),
              let endX = getDouble(args["end_x"]),
              let endY = getDouble(args["end_y"]) else {
            throw IOSControlError.invalidResponse
        }
        let duration = getDouble(args["duration"]) ?? 0.5
        try await client.swipe(startX: startX, startY: startY, endX: endX, endY: endY, duration: duration)
        return [.text("swiped (\(startX), \(startY)) -> (\(endX), \(endY))")]
    }

    private static func handleScroll(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let direction = args["direction"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }

        let distance = getDouble(args["distance"]) ?? 300
        let response = try await client.tree()
        let frame = response.tree.frame

        let x = getDouble(args["start_x"]) ?? (frame.width / 2)
        let y = getDouble(args["start_y"]) ?? (frame.height / 2)

        let endY = direction == "down" ? y - distance : y + distance
        try await client.swipe(startX: x, startY: y, endX: x, endY: endY, duration: 0.3)

        return [.text("scrolled \(direction) \(distance)px from (\(x), \(y))")]
    }

    private static func handleInputText(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let text = args["text"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }
        try await client.inputText(text)
        return [.text("typed \"\(text)\"")]
    }

    private static func handleGetUITree(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        var appBundleId = args["app_bundle_id"]?.stringValue
        if appBundleId == nil {
            appBundleId = try await client.foregroundApp().bundleId
        }
        let showCoords = args["show_coords"]?.boolValue ?? false

        let response = try await client.tree(appBundleId: appBundleId)
        return [.text(TreeFormatter.format(response.tree, showCoords: showCoords))]
    }

    private static func handleGetForegroundApp(client: IOSControlClient) async throws -> [Tool.Content] {
        let response = try await client.foregroundApp()
        return [.text(response.bundleId ?? "")]
    }

    private static func handleScreenshot(client: IOSControlClient) async throws -> [Tool.Content] {
        let data = try await client.screenshot()
        let base64 = data.base64EncodedString()
        return [.image(data: base64, mimeType: "image/png", metadata: nil)]
    }

    private static func handleListApps(client: IOSControlClient) async throws -> [Tool.Content] {
        let response = try await client.listApps()
        let list = response.bundleIds.joined(separator: "\n")
        return [.text(list)]
    }

    private static func handleLaunchApp(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let bundleId = args["bundle_id"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }
        try await client.launchApp(bundleId: bundleId)
        return [.text("launched \(bundleId)")]
    }

    private static func handleGoHome(client: IOSControlClient) async throws -> [Tool.Content] {
        try await client.goHome()
        return [.text("pressed home button")]
    }

    private static func handleTerminateApp(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let bundleId = args["bundle_id"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }
        try await client.terminateApp(bundleId: bundleId)
        return [.text("terminated \(bundleId)")]
    }

    private static func handleOpenURL(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let url = args["url"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }
        try await client.openURL(url)
        return [.text("opened \(url)")]
    }

    private static func handleGetPasteboard(client: IOSControlClient) async throws -> [Tool.Content] {
        let response = try await client.getPasteboard()
        return [.text(response.content ?? "")]
    }

    private static func handleSetPasteboard(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let content = args["content"]?.stringValue else {
            throw IOSControlError.invalidResponse
        }
        try await client.setPasteboard(content)
        return [.text("set pasteboard to \"\(content)\"")]
    }

    private static func handlePinch(client: IOSControlClient, args: [String: Value]) async throws -> [Tool.Content] {
        guard let x = getDouble(args["x"]),
              let y = getDouble(args["y"]),
              let scale = getDouble(args["scale"]) else {
            throw IOSControlError.invalidResponse
        }
        let velocity = getDouble(args["velocity"]) ?? 1.0
        try await client.pinch(x: x, y: y, scale: scale, velocity: velocity)
        let action = scale > 1.0 ? "zoomed in" : "zoomed out"
        return [.text("\(action) at (\(x), \(y)) with scale \(scale)")]
    }

    /// 서버가 실행 중인지 확인하고, 실행 중이지 않으면 SimulatorAgent 시작
    private static func ensureServerRunning(client: IOSControlClient) async throws {
        if await client.isServerRunning() {
            return
        }
        try await SimulatorAgentRunner.shared.start(timeout: 60)
    }
}
