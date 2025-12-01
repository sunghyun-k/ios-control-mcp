import Foundation

/// Accessibility 요소
public struct AXElement: Codable, Sendable {
    public let type: String
    public let identifier: String
    public let label: String
    public let value: String?
    public let placeholderValue: String?
    public let frame: AXFrame
    public let enabled: Bool
    public let hasFocus: Bool?
    public let children: [AXElement]?

    public init(
        type: String,
        identifier: String,
        label: String,
        value: String? = nil,
        placeholderValue: String? = nil,
        frame: AXFrame,
        enabled: Bool,
        hasFocus: Bool? = nil,
        children: [AXElement]? = nil
    ) {
        self.type = type
        self.identifier = identifier
        self.label = label
        self.value = value
        self.placeholderValue = placeholderValue
        self.frame = frame
        self.enabled = enabled
        self.hasFocus = hasFocus
        self.children = children
    }
}

/// Accessibility 요소의 프레임
public struct AXFrame: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// 중심 좌표
    public var center: (x: Double, y: Double) {
        (x + width / 2, y + height / 2)
    }
}

// MARK: - AXElement 유틸리티

extension AXElement {
    /// 라벨로 요소 찾기 (재귀적)
    public func findElement(byLabel label: String) -> AXElement? {
        findElement(byLabel: label, type: nil, index: nil)
    }

    /// 라벨과 인덱스로 요소 찾기 (재귀적)
    /// - Parameters:
    ///   - label: 찾을 라벨
    ///   - index: 동일 라벨 중 몇 번째인지 (0부터 시작). nil이면 첫 번째 요소 반환
    public func findElement(byLabel label: String, index: Int?) -> AXElement? {
        findElement(byLabel: label, type: nil, index: index)
    }

    /// 라벨, 타입, 인덱스로 요소 찾기 (재귀적)
    /// - Parameters:
    ///   - label: 찾을 라벨
    ///   - type: 요소 타입 (예: Button, TextField). nil이면 타입 무시
    ///   - index: 동일 조건 중 몇 번째인지 (0부터 시작). nil이면 첫 번째 요소 반환
    public func findElement(byLabel label: String, type: String?, index: Int?) -> AXElement? {
        var counter = 0
        return findElementRecursive(byLabel: label, type: type, targetIndex: index ?? 0, counter: &counter)
    }

    private func findElementRecursive(byLabel label: String, type: String?, targetIndex: Int, counter: inout Int) -> AXElement? {
        let labelMatches = self.label == label
        let typeMatches = type == nil || self.type == type

        if labelMatches && typeMatches {
            if counter == targetIndex {
                return self
            }
            counter += 1
        }

        if let children = children {
            for child in children {
                if let found = child.findElementRecursive(byLabel: label, type: type, targetIndex: targetIndex, counter: &counter) {
                    return found
                }
            }
        }

        return nil
    }

}
