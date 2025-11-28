import Foundation
import MCP
import Common

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

        // 도구 실행 전 서버 상태 확인 및 필요시 시작
        try await client.ensureServerRunning()

        switch name {
        case "tap":
            return try await handleTapElement(client: client, args: args)

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
}
