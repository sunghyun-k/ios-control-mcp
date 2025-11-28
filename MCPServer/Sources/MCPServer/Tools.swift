import MCP

/// MCP 도구 정의
enum Tools {
    static let all: [Tool] = [
    Tool(
        name: "tap",
        description: "라벨(텍스트)로 UI 요소를 찾아 탭합니다. 요소를 탭할 때 이 도구를 우선 사용하세요. get_ui_tree에서 확인한 텍스트를 label 파라미터에 전달합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "label": .object(["type": .string("string"), "description": .string("찾을 요소의 라벨/텍스트. get_ui_tree 결과에서 확인한 텍스트를 사용하세요.")]),
                "index": .object(["type": .string("integer"), "description": .string("동일 라벨이 여러 개일 때 몇 번째 요소인지 지정 (0부터 시작). get_ui_tree에서 라벨#인덱스 형식으로 표시됩니다.")]),
                "duration": .object(["type": .string("number"), "description": .string("롱프레스 시간(초)")]),
                "app_bundle_id": .object(["type": .string("string"), "description": .string("앱 번들 ID")])
            ]),
            "required": .array([.string("label")])
        ])
    ),
    Tool(
        name: "tap_coordinate",
        description: "iOS 시뮬레이터 화면의 특정 좌표를 탭합니다. 라벨로 요소를 찾을 수 없는 경우에만 사용하세요. 일반적인 경우 tap 도구를 우선 사용하세요.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "x": .object(["type": .string("number"), "description": .string("X 좌표")]),
                "y": .object(["type": .string("number"), "description": .string("Y 좌표")]),
                "duration": .object(["type": .string("number"), "description": .string("롱프레스 시간(초)")])
            ]),
            "required": .array([.string("x"), .string("y")])
        ])
    ),
    Tool(
        name: "swipe",
        description: "iOS 시뮬레이터 화면에서 스와이프를 수행합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "start_x": .object(["type": .string("number"), "description": .string("시작 X 좌표")]),
                "start_y": .object(["type": .string("number"), "description": .string("시작 Y 좌표")]),
                "end_x": .object(["type": .string("number"), "description": .string("끝 X 좌표")]),
                "end_y": .object(["type": .string("number"), "description": .string("끝 Y 좌표")]),
                "duration": .object(["type": .string("number"), "description": .string("스와이프 시간(초)")])
            ]),
            "required": .array([.string("start_x"), .string("start_y"), .string("end_x"), .string("end_y")])
        ])
    ),
    Tool(
        name: "scroll",
        description: "화면을 스크롤합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "direction": .object([
                    "type": .string("string"),
                    "enum": .array([.string("up"), .string("down")]),
                    "description": .string("스크롤 방향")
                ]),
                "distance": .object(["type": .string("number"), "description": .string("스크롤 거리(픽셀). 기본값 300")]),
                "start_x": .object(["type": .string("number"), "description": .string("시작 X 좌표")]),
                "start_y": .object(["type": .string("number"), "description": .string("시작 Y 좌표")])
            ]),
            "required": .array([.string("direction")])
        ])
    ),
    Tool(
        name: "input_text",
        description: "텍스트를 입력합니다. 키보드가 활성화되어 있어야 합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "text": .object(["type": .string("string"), "description": .string("입력할 텍스트")])
            ]),
            "required": .array([.string("text")])
        ])
    ),
    Tool(
        name: "get_ui_tree",
        description: "현재 화면의 UI 요소 트리를 반환합니다. 화면 상태를 확인할 때 이 도구를 우선 사용하세요. screenshot보다 빠르고 효율적입니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "app_bundle_id": .object(["type": .string("string"), "description": .string("앱 번들 ID")]),
                "show_coords": .object(["type": .string("boolean"), "description": .string("좌표 표시 여부. 기본값 false. tap_coordinate 사용 시에만 true로 설정하세요.")])
            ])
        ])
    ),
    Tool(
        name: "get_foreground_app",
        description: "현재 포그라운드에 있는 앱의 번들 ID를 반환합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    ),
    Tool(
        name: "screenshot",
        description: "현재 화면의 스크린샷을 캡처합니다. PNG 이미지를 반환합니다. 시각적 확인이 필요한 경우에만 사용하세요 (예: 이미지, 색상, 레이아웃 확인). 일반적인 UI 탐색에는 get_ui_tree를 사용하세요.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    ),
    Tool(
        name: "list_apps",
        description: "시뮬레이터에 설치된 앱들의 번들 ID 목록을 반환합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    ),
    Tool(
        name: "launch_app",
        description: "번들 ID로 앱을 실행합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "bundle_id": .object(["type": .string("string"), "description": .string("실행할 앱의 번들 ID")])
            ]),
            "required": .array([.string("bundle_id")])
        ])
    ),
    Tool(
        name: "go_home",
        description: "홈 화면으로 이동합니다. 현재 앱을 종료하고 홈 화면으로 돌아갑니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    ),
    Tool(
        name: "terminate_app",
        description: "실행 중인 앱을 강제 종료합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "bundle_id": .object(["type": .string("string"), "description": .string("종료할 앱의 번들 ID")])
            ]),
            "required": .array([.string("bundle_id")])
        ])
    ),
    Tool(
        name: "open_url",
        description: "URL을 엽니다. 딥링크나 웹 URL을 Safari에서 열 수 있습니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "url": .object(["type": .string("string"), "description": .string("열 URL (예: https://example.com 또는 myapp://path)")])
            ]),
            "required": .array([.string("url")])
        ])
    ),
    Tool(
        name: "get_pasteboard",
        description: "시뮬레이터 클립보드의 내용을 가져옵니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    ),
    Tool(
        name: "set_pasteboard",
        description: "시뮬레이터 클립보드에 텍스트를 설정합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "content": .object(["type": .string("string"), "description": .string("클립보드에 설정할 텍스트")])
            ]),
            "required": .array([.string("content")])
        ])
    ),
    Tool(
        name: "pinch",
        description: "핀치 제스처를 수행합니다. 지도나 이미지 확대/축소에 사용합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "x": .object(["type": .string("number"), "description": .string("핀치 중심 X 좌표")]),
                "y": .object(["type": .string("number"), "description": .string("핀치 중심 Y 좌표")]),
                "scale": .object(["type": .string("number"), "description": .string("줌 배율. 1.0 미만이면 줌 아웃, 1.0 초과면 줌 인 (예: 2.0은 2배 확대)")]),
                "velocity": .object(["type": .string("number"), "description": .string("핀치 속도. 기본값 1.0")])
            ]),
            "required": .array([.string("x"), .string("y"), .string("scale")])
        ])
    )
    ]
}
