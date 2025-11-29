import Foundation
import MCP

/// MCP 도구 인자 파싱 프로토콜
/// Value → JSON Data → Decodable 변환을 통해 타입 안전한 인자 파싱 제공
protocol ToolArguments: Decodable {
    init(from arguments: [String: Value]?) throws
}

extension ToolArguments {
    init(from arguments: [String: Value]?) throws {
        let args = arguments ?? [:]
        let jsonData = try JSONEncoder().encode(args)
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }
}

// MARK: - 인자 없는 도구용

struct EmptyArgs: ToolArguments {
    init(from arguments: [String: Value]?) throws {}
    init(from decoder: Decoder) throws {}
}

// MARK: - tap

struct TapArgs: ToolArguments {
    let label: String
    let index: Int?
    let duration: Double?
    let appBundleId: String?

    private enum CodingKeys: String, CodingKey {
        case label, index, duration
        case appBundleId = "app_bundle_id"
    }
}

// MARK: - tap_coordinate

struct TapCoordinateArgs: ToolArguments {
    let x: Double
    let y: Double
    let duration: Double?
}

// MARK: - swipe

struct SwipeArgs: ToolArguments {
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
    let duration: Double?
    let holdDuration: Double?

    private enum CodingKeys: String, CodingKey {
        case startX = "start_x"
        case startY = "start_y"
        case endX = "end_x"
        case endY = "end_y"
        case duration
        case holdDuration = "hold_duration"
    }
}

// MARK: - scroll

struct ScrollArgs: ToolArguments {
    let direction: String
    let distance: Double?
    let startX: Double?
    let startY: Double?

    private enum CodingKeys: String, CodingKey {
        case direction, distance
        case startX = "start_x"
        case startY = "start_y"
    }
}

// MARK: - input_text

struct InputTextArgs: ToolArguments {
    let text: String
}

// MARK: - get_ui_tree

struct GetUITreeArgs: ToolArguments {
    let appBundleId: String?
    let showCoords: Bool?

    private enum CodingKeys: String, CodingKey {
        case appBundleId = "app_bundle_id"
        case showCoords = "show_coords"
    }
}

// MARK: - launch_app, terminate_app

struct BundleIdArgs: ToolArguments {
    let bundleId: String

    private enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
    }
}

// MARK: - open_url

struct URLArgs: ToolArguments {
    let url: String
}

// MARK: - set_pasteboard

struct ContentArgs: ToolArguments {
    let content: String
}

// MARK: - pinch

struct PinchArgs: ToolArguments {
    let x: Double
    let y: Double
    let scale: Double
    let velocity: Double?
}

// MARK: - drag

struct DragArgs: ToolArguments {
    let fromLabel: String
    let fromIndex: Int?
    let toLabel: String
    let toIndex: Int?
    let holdDuration: Double?
    let appBundleId: String?

    private enum CodingKeys: String, CodingKey {
        case fromLabel = "from_label"
        case fromIndex = "from_index"
        case toLabel = "to_label"
        case toIndex = "to_index"
        case holdDuration = "hold_duration"
        case appBundleId = "app_bundle_id"
    }
}
