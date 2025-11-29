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

// MARK: - 좌표 파싱 헬퍼

struct Coordinate {
    let x: Double
    let y: Double

    /// "x,y" 문자열에서 좌표 파싱
    init?(from string: String) {
        let parts = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let x = Double(parts[0]),
              let y = Double(parts[1]) else {
            return nil
        }
        self.x = x
        self.y = y
    }
}

enum CoordinateParseError: LocalizedError {
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let value):
            return "Invalid coordinate format '\(value)'. Expected 'x,y' (e.g., '100,200')"
        }
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
    let elementType: String?
    let index: Int?
    let duration: Double?

    private enum CodingKeys: String, CodingKey {
        case label
        case elementType = "element_type"
        case index
        case duration
    }
}

// MARK: - tap_coordinate

struct TapCoordinateArgs: ToolArguments {
    let coordinate: String
    let duration: Double?

    func parseCoordinate() throws -> Coordinate {
        guard let coord = Coordinate(from: coordinate) else {
            throw CoordinateParseError.invalidFormat(coordinate)
        }
        return coord
    }
}

// MARK: - swipe

struct SwipeArgs: ToolArguments {
    let start: String
    let end: String
    let duration: Double?
    let holdDuration: Double?

    private enum CodingKeys: String, CodingKey {
        case start, end, duration
        case holdDuration = "hold_duration"
    }

    func parseStart() throws -> Coordinate {
        guard let coord = Coordinate(from: start) else {
            throw CoordinateParseError.invalidFormat(start)
        }
        return coord
    }

    func parseEnd() throws -> Coordinate {
        guard let coord = Coordinate(from: end) else {
            throw CoordinateParseError.invalidFormat(end)
        }
        return coord
    }
}

// MARK: - scroll

struct ScrollArgs: ToolArguments {
    let direction: String
    let distance: Double?
    let duration: Double?
    let start: String?

    func parseStart() -> Coordinate? {
        guard let start = start else { return nil }
        return Coordinate(from: start)
    }
}

// MARK: - input_text

struct InputTextArgs: ToolArguments {
    let text: String
}

// MARK: - get_ui_tree

struct GetUITreeArgs: ToolArguments {
    let showCoords: Bool?

    private enum CodingKeys: String, CodingKey {
        case showCoords = "show_coords"
    }
}

// MARK: - launch_app

struct BundleIdArgs: ToolArguments {
    let bundleId: String

    private enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
    }
}

// MARK: - pinch

struct PinchArgs: ToolArguments {
    let center: String?
    let scale: Double
    let velocity: Double?

    func parseCenter() -> Coordinate? {
        guard let center = center else { return nil }
        return Coordinate(from: center)
    }
}

// MARK: - drag

struct DragArgs: ToolArguments {
    let fromLabel: String
    let fromElementType: String?
    let fromIndex: Int?
    let toLabel: String
    let toElementType: String?
    let toIndex: Int?
    let duration: Double?
    let holdDuration: Double?

    private enum CodingKeys: String, CodingKey {
        case fromLabel = "from_label"
        case fromElementType = "from_element_type"
        case fromIndex = "from_index"
        case toLabel = "to_label"
        case toElementType = "to_element_type"
        case toIndex = "to_index"
        case duration
        case holdDuration = "hold_duration"
    }
}

// MARK: - select_device

struct SelectDeviceArgs: ToolArguments {
    let udid: String?
}
