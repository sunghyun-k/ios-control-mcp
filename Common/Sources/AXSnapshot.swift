import Foundation

/// XCUIApplication.snapshot().dictionaryRepresentation의 JSON 구조를 파싱하는 모델
public struct AXSnapshot: Codable, Sendable {
    public let children: [AXSnapshot]?
    public let displayID: Int?
    public let elementType: Int?
    public let enabled: Bool?
    public let frame: AXFrame?
    public let hasFocus: Bool?
    public let horizontalSizeClass: Int?
    public let identifier: String?
    public let label: String?
    public let placeholderValue: String?
    public let selected: Bool?
    public let title: String?
    public let value: String?
    public let verticalSizeClass: Int?
    public let windowContextID: Int?

    public init(
        children: [AXSnapshot]? = nil,
        displayID: Int? = nil,
        elementType: Int? = nil,
        enabled: Bool? = nil,
        frame: AXFrame? = nil,
        hasFocus: Bool? = nil,
        horizontalSizeClass: Int? = nil,
        identifier: String? = nil,
        label: String? = nil,
        placeholderValue: String? = nil,
        selected: Bool? = nil,
        title: String? = nil,
        value: String? = nil,
        verticalSizeClass: Int? = nil,
        windowContextID: Int? = nil,
    ) {
        self.children = children
        self.displayID = displayID
        self.elementType = elementType
        self.enabled = enabled
        self.frame = frame
        self.hasFocus = hasFocus
        self.horizontalSizeClass = horizontalSizeClass
        self.identifier = identifier
        self.label = label
        self.placeholderValue = placeholderValue
        self.selected = selected
        self.title = title
        self.value = value
        self.verticalSizeClass = verticalSizeClass
        self.windowContextID = windowContextID
    }
}

/// 요소의 위치와 크기
public struct AXFrame: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    enum CodingKeys: String, CodingKey {
        case x = "X"
        case y = "Y"
        case width = "Width"
        case height = "Height"
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// 중심점 좌표
    public var center: (x: Double, y: Double) {
        (x + width / 2, y + height / 2)
    }

    public var isZero: Bool {
        width == 0 && height == 0
    }
}

/// XCUIElement.ElementType의 주요 값들
/// - Int rawValue는 XCUIElement.ElementType과 매칭
/// - JSON 직렬화 시 snake_case 문자열로 변환
public enum AXElementType: Int, Sendable, CaseIterable, Codable {
    case any = 0
    case other = 1
    case application = 2
    case group = 3
    case window = 4
    case sheet = 5
    case drawer = 6
    case alert = 7
    case dialog = 8
    case button = 9
    case radioButton = 10
    case radioGroup = 11
    case checkBox = 12
    case disclosureTriangle = 13
    case popUpButton = 14
    case comboBox = 15
    case menuButton = 16
    case toolbarButton = 17
    case popover = 18
    case keyboard = 19
    case key = 20
    case navigationBar = 21
    case tabBar = 22
    case tabGroup = 23
    case toolbar = 24
    case statusBar = 25
    case table = 26
    case tableRow = 27
    case tableColumn = 28
    case outline = 29
    case outlineRow = 30
    case browser = 31
    case collectionView = 32
    case slider = 33
    case pageIndicator = 34
    case progressIndicator = 35
    case activityIndicator = 36
    case segmentedControl = 37
    case picker = 38
    case pickerWheel = 39
    case `switch` = 40
    case toggle = 41
    case link = 42
    case image = 43
    case icon = 44
    case searchField = 45
    case scrollView = 46
    case scrollBar = 47
    case staticText = 48
    case textField = 49
    case secureTextField = 50
    case datePicker = 51
    case textView = 52
    case menu = 53
    case menuItem = 54
    case menuBar = 55
    case menuBarItem = 56
    case map = 57
    case webView = 58
    case incrementArrow = 59
    case decrementArrow = 60
    case timeline = 61
    case ratingIndicator = 62
    case valueIndicator = 63
    case splitGroup = 64
    case splitter = 65
    case relevanceIndicator = 66
    case colorWell = 67
    case helpTag = 68
    case matte = 69
    case dockItem = 70
    case ruler = 71
    case rulerMarker = 72
    case grid = 73
    case levelIndicator = 74
    case cell = 75
    case layoutArea = 76
    case layoutItem = 77
    case handle = 78
    case stepper = 79
    case tab = 80
    case touchBar = 81
    case statusItem = 82

    /// 문자열 이름 (snake_case)
    public var name: String {
        switch self {
        case .any: "any"
        case .other: "other"
        case .application: "application"
        case .group: "group"
        case .window: "window"
        case .sheet: "sheet"
        case .drawer: "drawer"
        case .alert: "alert"
        case .dialog: "dialog"
        case .button: "button"
        case .radioButton: "radio_button"
        case .radioGroup: "radio_group"
        case .checkBox: "check_box"
        case .disclosureTriangle: "disclosure_triangle"
        case .popUpButton: "pop_up_button"
        case .comboBox: "combo_box"
        case .menuButton: "menu_button"
        case .toolbarButton: "toolbar_button"
        case .popover: "popover"
        case .keyboard: "keyboard"
        case .key: "key"
        case .navigationBar: "navigation_bar"
        case .tabBar: "tab_bar"
        case .tabGroup: "tab_group"
        case .toolbar: "toolbar"
        case .statusBar: "status_bar"
        case .table: "table"
        case .tableRow: "table_row"
        case .tableColumn: "table_column"
        case .outline: "outline"
        case .outlineRow: "outline_row"
        case .browser: "browser"
        case .collectionView: "collection_view"
        case .slider: "slider"
        case .pageIndicator: "page_indicator"
        case .progressIndicator: "progress_indicator"
        case .activityIndicator: "activity_indicator"
        case .segmentedControl: "segmented_control"
        case .picker: "picker"
        case .pickerWheel: "picker_wheel"
        case .switch: "switch"
        case .toggle: "toggle"
        case .link: "link"
        case .image: "image"
        case .icon: "icon"
        case .searchField: "search_field"
        case .scrollView: "scroll_view"
        case .scrollBar: "scroll_bar"
        case .staticText: "static_text"
        case .textField: "text_field"
        case .secureTextField: "secure_text_field"
        case .datePicker: "date_picker"
        case .textView: "text_view"
        case .menu: "menu"
        case .menuItem: "menu_item"
        case .menuBar: "menu_bar"
        case .menuBarItem: "menu_bar_item"
        case .map: "map"
        case .webView: "web_view"
        case .incrementArrow: "increment_arrow"
        case .decrementArrow: "decrement_arrow"
        case .timeline: "timeline"
        case .ratingIndicator: "rating_indicator"
        case .valueIndicator: "value_indicator"
        case .splitGroup: "split_group"
        case .splitter: "splitter"
        case .relevanceIndicator: "relevance_indicator"
        case .colorWell: "color_well"
        case .helpTag: "help_tag"
        case .matte: "matte"
        case .dockItem: "dock_item"
        case .ruler: "ruler"
        case .rulerMarker: "ruler_marker"
        case .grid: "grid"
        case .levelIndicator: "level_indicator"
        case .cell: "cell"
        case .layoutArea: "layout_area"
        case .layoutItem: "layout_item"
        case .handle: "handle"
        case .stepper: "stepper"
        case .tab: "tab"
        case .touchBar: "touch_bar"
        case .statusItem: "status_item"
        }
    }

    /// 문자열 이름으로 초기화
    public init?(name: String) {
        let found = Self.allCases.first { $0.name == name }
        guard let found else { return nil }
        self = found
    }

    /// 자주 사용되는 element type들
    public static var commonTypes: [AXElementType] {
        [
            .button,
            .staticText,
            .textField,
            .secureTextField,
            .searchField,
            .image,
            .link,
            .cell,
            .switch,
            .slider,
            .toggle,
            .checkBox,
            .navigationBar,
            .tabBar,
            .table,
            .scrollView,
            .collectionView,
            .alert,
            .picker,
            .pickerWheel,
            .datePicker,
            .textView,
        ]
    }

    /// 자주 사용되는 element type들의 이름 목록
    public static var commonTypeNames: [String] {
        commonTypes.map(\.name)
    }
}
