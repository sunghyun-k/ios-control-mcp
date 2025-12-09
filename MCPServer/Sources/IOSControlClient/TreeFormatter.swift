import Foundation
import Common

// MARK: - TreeFormatter

public enum TreeFormatter {
    /// 트리를 YAML 형식으로 포맷팅된 문자열로 변환
    public static func format(_ element: AXElement, showCoords: Bool = false) -> String {
        // 화면 크기 (루트 요소의 frame 사용)
        let screenBounds = ScreenBounds(width: element.frame.width, height: element.frame.height)

        // 키보드 Y 좌표 찾기 (키보드가 있으면 그 아래 영역 필터링)
        let keyboardTopY = findKeyboardTopY(element)

        // 먼저 라벨 등장 횟수를 계산 (키보드 영역 제외)
        var labelCounts: [String: Int] = [:]
        countLabels(element, counts: &labelCounts, keyboardTopY: keyboardTopY, screenBounds: screenBounds)

        // 중복 라벨만 추적 (2회 이상 등장)
        let duplicateLabels = Set(labelCounts.filter { $0.value > 1 }.keys)

        // 현재 인덱스 추적용
        var labelIndices: [String: Int] = [:]

        return formatElement(element, indent: 0, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds).joined(separator: "\n")
    }

    /// 화면 크기 정보
    struct ScreenBounds {
        let width: Double
        let height: Double

        /// 요소의 중심점이 화면 안에 있는지 확인
        func containsCenter(of element: AXElement) -> Bool {
            let center = element.frame.center
            return center.x >= 0 && center.x <= width && center.y >= 0 && center.y <= height
        }
    }

    /// 키보드의 상단 Y 좌표를 찾음
    private static func findKeyboardTopY(_ element: AXElement) -> Double? {
        // Keyboard 타입이면 해당 요소의 Y 좌표 반환
        if element.type == "Keyboard" {
            return element.frame.y
        }

        // 자식들에서 재귀 탐색
        if let children = element.children {
            for child in children {
                if let y = findKeyboardTopY(child) {
                    return y
                }
            }
        }

        return nil
    }

    /// 트리 내 모든 라벨 등장 횟수 계산 (키보드 영역, 화면 밖 요소 제외)
    private static func countLabels(_ element: AXElement, counts: inout [String: Int], keyboardTopY: Double?, screenBounds: ScreenBounds) {
        // 키보드 관련 요소는 제외
        if isKeyboardElement(element) {
            return
        }

        // 키보드에 가려진 요소는 제외
        if let keyboardY = keyboardTopY, isObscuredByKeyboard(element, keyboardTopY: keyboardY) {
            return
        }

        // 화면 밖 요소는 제외
        if !screenBounds.containsCenter(of: element) {
            return
        }

        let label = element.label
        if !label.isEmpty {
            counts[label, default: 0] += 1
        }

        if let children = element.children {
            for child in children {
                countLabels(child, counts: &counts, keyboardTopY: keyboardTopY, screenBounds: screenBounds)
            }
        }
    }

    /// 키보드 관련 요소인지 확인
    static func isKeyboardElement(_ element: AXElement) -> Bool {
        // 키보드 타입들
        let keyboardTypes: Set<String> = ["Keyboard", "Key"]
        if keyboardTypes.contains(element.type) {
            return true
        }

        // 키보드 관련 라벨 패턴
        let keyboardLabelPatterns = ["Next keyboard", "Dictate", "Typing Predictions", "이모지"]
        let label = element.label
        for pattern in keyboardLabelPatterns {
            if label.contains(pattern) {
                return true
            }
        }

        return false
    }

    /// 요소가 키보드에 의해 가려졌는지 확인
    static func isObscuredByKeyboard(_ element: AXElement, keyboardTopY: Double) -> Bool {
        // 요소의 상단이 키보드 상단보다 아래에 있으면 가려진 것
        return element.frame.y >= keyboardTopY
    }
}

// MARK: - Private Formatting

/// 숨길 요소 패턴
private let hiddenPatterns: [String] = ["스크롤 막대", "scroll bar"]

/// Switch/Toggle은 내부 자식을 출력하지 않음 (내부 구현 디테일)
private let leafTypes: Set<String> = ["Switch", "Toggle"]

private func formatElement(_ element: AXElement, indent: Int, showCoords: Bool, duplicateLabels: Set<String>, labelIndices: inout [String: Int], keyboardTopY: Double?, screenBounds: TreeFormatter.ScreenBounds) -> [String] {
    // 숨길 요소 제외
    if shouldHide(element, keyboardTopY: keyboardTopY, screenBounds: screenBounds) {
        return []
    }

    // 단일 자식 체인 처리: 현재 요소가 무의미하고 자식이 1개면 체인으로 연결
    if let chainResult = tryFormatChain(element, indent: indent, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds) {
        return chainResult
    }

    var lines: [String] = []
    let prefix = String(repeating: "  ", count: indent)

    // 현재 요소 출력 (YAML 리스트 형식)
    let (mainLine, metadataLines) = formatSingleElement(element, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices)

    let children = element.children ?? []
    let visibleChildren = children.filter { !shouldHide($0, keyboardTopY: keyboardTopY, screenBounds: screenBounds) }
    let hasChildren = !visibleChildren.isEmpty && !leafTypes.contains(element.type)

    // 자식이 있으면 콜론으로 끝남
    if hasChildren {
        lines.append("\(prefix)- \(mainLine):")
    } else {
        lines.append("\(prefix)- \(mainLine)")
    }

    // 메타데이터 라인들 추가 (자식과 같은 들여쓰기)
    for metadata in metadataLines {
        lines.append("\(prefix)  - \(metadata)")
    }

    // Switch/Toggle은 자식 출력 안함
    if leafTypes.contains(element.type) {
        return lines
    }

    // 자식 요소들 출력 (Y축 그룹화 적용)
    lines.append(contentsOf: formatChildrenWithRowGrouping(children, indent: indent + 1, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))

    return lines
}

/// 자식 요소들을 Y축 그룹화하여 출력
private func formatChildrenWithRowGrouping(_ children: [AXElement], indent: Int, showCoords: Bool, duplicateLabels: Set<String>, labelIndices: inout [String: Int], keyboardTopY: Double?, screenBounds: TreeFormatter.ScreenBounds) -> [String] {
    var lines: [String] = []
    let prefix = String(repeating: "  ", count: indent)

    // 자식이 4개 미만이면 그룹화 없이 출력
    let visibleChildren = children.filter { !shouldHide($0, keyboardTopY: keyboardTopY, screenBounds: screenBounds) }
    if visibleChildren.count < 4 {
        for child in children {
            lines.append(contentsOf: formatElement(child, indent: indent, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))
        }
        return lines
    }

    // Y축 기준으로 그룹화
    let groups = groupChildrenByRow(children, keyboardTopY: keyboardTopY, screenBounds: screenBounds)

    for group in groups {
        if group.count == 1 {
            // 단일 요소는 그냥 출력
            lines.append(contentsOf: formatElement(group[0], indent: indent, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))
        } else {
            // 여러 요소는 row로 묶어서 출력
            lines.append("\(prefix)- row:")
            for element in group {
                lines.append(contentsOf: formatElement(element, indent: indent + 1, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))
            }
        }
    }

    return lines
}

/// 단일 자식 체인 시도 - 무의미한 중간 노드들을 > 로 연결
private func tryFormatChain(_ element: AXElement, indent: Int, showCoords: Bool, duplicateLabels: Set<String>, labelIndices: inout [String: Int], keyboardTopY: Double?, screenBounds: TreeFormatter.ScreenBounds) -> [String]? {
    var chain: [AXElement] = [element]
    var current = element

    // 단일 자식 체인 수집
    while let children = current.children, children.count == 1 {
        let child = children[0]
        if shouldHide(child, keyboardTopY: keyboardTopY, screenBounds: screenBounds) {
            break
        }
        chain.append(child)
        current = child
    }

    // 체인이 2개 이상이고, 중간에 무의미한 노드가 있을 때만 체인 처리
    let meaningfulCount = chain.filter { isMeaningful($0) }.count
    let meaninglessCount = chain.count - meaningfulCount

    // 무의미한 노드가 없으면 체인 처리 안함
    if meaninglessCount == 0 {
        return nil
    }

    // 의미있는 노드만 추출하여 체인으로 표시
    let meaningfulElements = chain.filter { isMeaningful($0) }

    var lines: [String] = []
    let prefix = String(repeating: "  ", count: indent)

    if meaningfulElements.isEmpty {
        // 모두 무의미하면 생략하고 마지막 노드의 자식만 처리
        let lastElement = chain.last!
        if let children = lastElement.children {
            lines.append(contentsOf: formatChildrenWithRowGrouping(children, indent: indent, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))
        }
    } else if meaningfulElements.count == 1 {
        // 의미있는 노드가 1개면 그냥 출력
        let (mainLine, metadataLines) = formatSingleElement(meaningfulElements[0], showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices)

        // 체인 끝 노드의 자식들 처리 (단, Switch/Toggle은 자식 출력 안함)
        let lastElement = chain.last!
        let visibleChildren = lastElement.children?.filter { !shouldHide($0, keyboardTopY: keyboardTopY, screenBounds: screenBounds) } ?? []
        let hasChildren = !leafTypes.contains(lastElement.type) && !visibleChildren.isEmpty

        if hasChildren {
            lines.append("\(prefix)- \(mainLine):")
        } else {
            lines.append("\(prefix)- \(mainLine)")
        }

        // 메타데이터 라인들 추가
        for metadata in metadataLines {
            lines.append("\(prefix)  - \(metadata)")
        }

        if !leafTypes.contains(lastElement.type), let children = lastElement.children {
            lines.append(contentsOf: formatChildrenWithRowGrouping(children, indent: indent + 1, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))
        }
    } else {
        // 여러 의미있는 노드는 > 로 연결
        let chainStr = meaningfulElements.map { formatSingleElement($0, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices).0 }.joined(separator: " > ")

        // 체인 끝 노드의 자식들 처리 (단, Switch/Toggle은 자식 출력 안함)
        let lastElement = chain.last!
        let visibleChildren = lastElement.children?.filter { !shouldHide($0, keyboardTopY: keyboardTopY, screenBounds: screenBounds) } ?? []
        let hasChildren = !leafTypes.contains(lastElement.type) && !visibleChildren.isEmpty

        if hasChildren {
            lines.append("\(prefix)- \(chainStr):")
        } else {
            lines.append("\(prefix)- \(chainStr)")
        }

        if !leafTypes.contains(lastElement.type), let children = lastElement.children {
            lines.append(contentsOf: formatChildrenWithRowGrouping(children, indent: indent + 1, showCoords: showCoords, duplicateLabels: duplicateLabels, labelIndices: &labelIndices, keyboardTopY: keyboardTopY, screenBounds: screenBounds))
        }
    }

    return lines
}

/// 요소가 의미있는지 확인 (라벨, 식별자, 값이 있거나 특정 타입)
private func isMeaningful(_ element: AXElement) -> Bool {
    // 라벨이 있으면 의미있음
    if !element.label.isEmpty {
        return true
    }

    // 값이 있으면 의미있음
    if let value = element.value, !value.isEmpty {
        return true
    }

    // 플레이스홀더가 있으면 의미있음
    if let placeholder = element.placeholderValue, !placeholder.isEmpty {
        return true
    }

    // Other, Window, Group 등 컨테이너 타입은 무의미
    let containerTypes: Set<String> = ["Other", "Window", "Group"]
    if containerTypes.contains(element.type) {
        return false
    }

    // 그 외 타입은 의미있음 (Button, Cell, Switch 등)
    return true
}

/// 단일 요소를 문자열로 포맷 - (메인 라인, 메타데이터 라인들) 반환
private func formatSingleElement(_ element: AXElement, showCoords: Bool, duplicateLabels: Set<String>, labelIndices: inout [String: Int]) -> (String, [String]) {
    var mainParts: [String] = []
    var attributes: [String] = []
    var metadataLines: [String] = []

    // 타입
    let typeStr = formatType(element.type)

    // 라벨 (중복인 경우 인덱스 추가)
    var labelStr = ""
    if !element.label.isEmpty {
        let label = element.label
        if duplicateLabels.contains(label) {
            let index = labelIndices[label, default: 0]
            labelIndices[label] = index + 1
            labelStr = "\"\(label)\"#\(index)"
        } else {
            labelStr = "\"\(label)\""
        }
    }

    // 메인 라인: type "label"
    if labelStr.isEmpty {
        mainParts.append(typeStr)
    } else {
        mainParts.append("\(typeStr) \(labelStr)")
    }

    // 값 (Switch/Toggle의 경우 on/off로 표시)
    if let value = element.value, !value.isEmpty {
        if element.type == "Switch" || element.type == "Toggle" {
            let onOff = value == "1" ? "on" : "off"
            attributes.append(onOff)
        } else {
            // 값은 메타데이터로
            metadataLines.append("/value: \(value)")
        }
    }

    // 플레이스홀더 (TextField 등) - 메타데이터로
    if let placeholder = element.placeholderValue, !placeholder.isEmpty {
        metadataLines.append("/placeholder: \(placeholder)")
    }

    // enabled가 false이면 표시
    if !element.enabled {
        attributes.append("disabled")
    }

    // 포커스 상태 표시 (입력 필드만)
    if let hasFocus = element.hasFocus, hasFocus {
        attributes.append("focused")
    }

    // 좌표
    if showCoords {
        let cx = Int(element.frame.center.x)
        let cy = Int(element.frame.center.y)
        attributes.append("@(\(cx),\(cy))")
    }

    // 속성들을 대괄호 안에 표시
    var mainLine = mainParts.joined(separator: " ")
    if !attributes.isEmpty {
        mainLine += " [\(attributes.joined(separator: "] ["))]"
    }

    return (mainLine, metadataLines)
}

/// 타입을 짧은 형태로 포맷
private func formatType(_ type: String) -> String {
    let shortTypes: [String: String] = [
        "StaticText": "Text",
        "TextField": "Input",
        "SecureTextField": "Password",
        "NavigationBar": "NavBar",
        "TabBar": "TabBar",
        "SearchField": "Search",
    ]
    return shortTypes[type] ?? type
}

/// 숨길 요소인지 확인
private func shouldHide(_ element: AXElement, keyboardTopY: Double?, screenBounds: TreeFormatter.ScreenBounds) -> Bool {
    // 기존 숨김 패턴 확인
    let label = element.label.lowercased()
    for pattern in hiddenPatterns {
        if label.contains(pattern.lowercased()) {
            return true
        }
    }

    // 키보드 관련 요소 확인
    if TreeFormatter.isKeyboardElement(element) {
        return true
    }

    // 키보드에 가려진 요소 확인
    if let keyboardY = keyboardTopY, TreeFormatter.isObscuredByKeyboard(element, keyboardTopY: keyboardY) {
        return true
    }

    // 화면 밖 요소 확인 (중심점 기준)
    // 주의: 이 검사는 WebView 컨텍스트에서는 적용하지 않음 (웹 콘텐츠는 자체 스크롤 영역을 가짐)
    // WebView 내부 요소들은 screenBounds 기반 필터링을 완전히 건너뜀
    // (WebView 내부 요소인지는 호출 스택에서 판단해야 하므로, 여기서는 검사하지 않음)

    return false
}

// MARK: - Y축 그룹화

/// 두 요소의 Y 범위가 겹치는지 확인
private func framesOverlapVertically(_ a: AXElement, _ b: AXElement) -> Bool {
    let aTop = a.frame.y
    let aBottom = a.frame.y + a.frame.height
    let bTop = b.frame.y
    let bBottom = b.frame.y + b.frame.height

    // 겹침 조건: max(top1, top2) < min(bottom1, bottom2)
    return max(aTop, bTop) < min(aBottom, bBottom)
}

/// 자식 요소들을 Y축 기준으로 그룹화
/// - Returns: 각 행별 요소 배열 (Y 좌표 순으로 정렬됨)
private func groupChildrenByRow(_ children: [AXElement], keyboardTopY: Double?, screenBounds: TreeFormatter.ScreenBounds) -> [[AXElement]] {
    guard !children.isEmpty else { return [] }

    // 숨길 요소 제외
    let visibleChildren = children.filter { !shouldHide($0, keyboardTopY: keyboardTopY, screenBounds: screenBounds) }
    guard !visibleChildren.isEmpty else { return [] }

    // Y 좌표 순으로 정렬
    let sorted = visibleChildren.sorted { $0.frame.y < $1.frame.y }

    var groups: [[AXElement]] = []
    var currentGroup: [AXElement] = [sorted[0]]

    for i in 1..<sorted.count {
        let current = sorted[i]

        // 현재 그룹의 어느 요소와도 Y가 겹치는지 확인
        let overlapsWithGroup = currentGroup.contains { framesOverlapVertically($0, current) }

        if overlapsWithGroup {
            currentGroup.append(current)
        } else {
            // 새 그룹 시작
            groups.append(currentGroup)
            currentGroup = [current]
        }
    }

    // 마지막 그룹 추가
    groups.append(currentGroup)

    // 각 그룹 내에서 X 좌표 순으로 정렬
    return groups.map { group in
        group.sorted { $0.frame.x < $1.frame.x }
    }
}
