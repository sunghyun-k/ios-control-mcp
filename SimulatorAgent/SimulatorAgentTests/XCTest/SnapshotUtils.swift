import Common
import XCTest

enum SnapshotUtils {
    /// XCUIElementSnapshot dictionary를 AXElement로 변환
    static func convertToAXElement(_ dict: [XCUIElement.AttributeName: Any]) -> AXElement {
        let frame = dict[.init(rawValue: "frame")] as? [String: Double] ?? [:]
        let children = (dict[.init(rawValue: "children")] as? [[XCUIElement.AttributeName: Any]])?
            .map { convertToAXElement($0) }

        return AXElement(
            type: elementTypeName(dict[.init(rawValue: "elementType")] as? Int ?? 0),
            identifier: dict[.init(rawValue: "identifier")] as? String ?? "",
            label: dict[.init(rawValue: "label")] as? String ?? "",
            value: dict[.init(rawValue: "value")] as? String,
            placeholderValue: dict[.init(rawValue: "placeholderValue")] as? String,
            frame: AXFrame(
                x: frame["X"] ?? 0,
                y: frame["Y"] ?? 0,
                width: frame["Width"] ?? 0,
                height: frame["Height"] ?? 0
            ),
            enabled: dict[.init(rawValue: "enabled")] as? Bool ?? true,
            children: children
        )
    }

    /// Element type 숫자를 문자열로 변환
    static func elementTypeName(_ type: Int) -> String {
        let names: [Int: String] = [
            0: "Any", 1: "Other", 2: "Application", 3: "Group",
            4: "Window", 5: "Sheet", 6: "Drawer", 7: "Alert",
            8: "Dialog", 9: "Button", 10: "RadioButton",
            11: "RadioGroup", 12: "CheckBox", 13: "DisclosureTriangle",
            14: "PopUpButton", 15: "ComboBox", 16: "MenuButton",
            17: "ToolbarButton", 18: "Popover", 19: "Keyboard",
            20: "Key", 21: "NavigationBar", 22: "TabBar",
            23: "TabGroup", 24: "Toolbar", 25: "StatusBar",
            26: "Table", 27: "TableRow", 28: "TableColumn",
            29: "Outline", 30: "OutlineRow", 31: "Browser",
            32: "CollectionView", 33: "Slider", 34: "PageIndicator",
            35: "ProgressIndicator", 36: "ActivityIndicator",
            37: "SegmentedControl", 38: "Picker", 39: "PickerWheel",
            40: "Switch", 41: "Toggle", 42: "Link",
            43: "Image", 44: "Icon", 45: "SearchField",
            46: "ScrollView", 47: "ScrollBar", 48: "StaticText",
            49: "TextField", 50: "SecureTextField", 51: "DatePicker",
            52: "TextView", 53: "Menu", 54: "MenuItem",
            55: "MenuBar", 56: "MenuBarItem", 57: "Map",
            58: "WebView", 59: "IncrementArrow", 60: "DecrementArrow",
            61: "Timeline", 62: "RatingIndicator", 63: "ValueIndicator",
            64: "SplitGroup", 65: "Splitter", 66: "RelevanceIndicator",
            67: "ColorWell", 68: "HelpTag", 69: "Matte",
            70: "DockItem", 71: "Ruler", 72: "RulerMarker",
            73: "Grid", 74: "LevelIndicator", 75: "Cell",
            76: "LayoutArea", 77: "LayoutItem", 78: "Handle",
            79: "Stepper", 80: "Tab", 81: "TouchBar",
            82: "StatusItem"
        ]
        return names[type] ?? "Unknown(\(type))"
    }

    /// 스냅샷 트리에서 특정 패턴의 identifier를 찾아 추출
    static func findIdentifier(
        in dict: [XCUIElement.AttributeName: Any],
        matching pattern: NSRegularExpression,
        captureGroup: Int = 1
    ) -> String? {
        // 현재 노드의 identifier 확인
        if let identifier = dict[.init(rawValue: "identifier")] as? String {
            let range = NSRange(identifier.startIndex..., in: identifier)
            if let match = pattern.firstMatch(in: identifier, range: range),
               let capturedRange = Range(match.range(at: captureGroup), in: identifier) {
                return String(identifier[capturedRange])
            }
        }

        // 자식 노드 재귀 탐색
        if let children = dict[.init(rawValue: "children")] as? [[XCUIElement.AttributeName: Any]] {
            for child in children {
                if let result = findIdentifier(in: child, matching: pattern, captureGroup: captureGroup) {
                    return result
                }
            }
        }

        return nil
    }
}
