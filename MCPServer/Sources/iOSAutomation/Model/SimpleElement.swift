import Common
import Foundation

/// 간소화된 UI 요소
/// - 단일 자식 체인은 types 배열로 압축
public struct SimpleElement: Sendable {
    /// 타입 체인 (단일 자식일 때 합쳐짐) ex: [.cell, .button]
    public let types: [AXElementType]
    public let label: String?
    public let identifier: String?
    public let value: String?
    public let placeholderValue: String?
    public let frame: AXFrame
    public let children: [SimpleElement]?
}

// MARK: - AXSnapshot → SimpleElement 변환

extension AXSnapshot {
    /// 간소화된 SimpleElement로 변환
    public func toSimpleElement() -> SimpleElement? {
        toSimpleElementInternal(typeChain: [])
    }

    private func toSimpleElementInternal(typeChain: [AXElementType]) -> SimpleElement? {
        // frame이 0,0,0,0인 요소는 hittable하지 않음
        if let frame, frame.isZero {
            return nil
        }

        let currentType = type ?? .other
        let newChain = typeChain + [currentType]

        // 현재 노드에 유의미한 정보가 없는지 확인
        let hasNoInfo = (label == nil || label?.isEmpty == true)
            && (identifier == nil || identifier?.isEmpty == true)
            && (value == nil || value?.isEmpty == true)
            && (placeholderValue == nil || placeholderValue?.isEmpty == true)

        // 먼저 자식들을 변환 (변환 후 개수가 달라질 수 있음)
        let convertedChildren = children?
            .compactMap { $0.toSimpleElement() }
            .nilIfEmpty

        // 변환된 자식이 정확히 1개이고 현재 노드에 정보가 없으면 체인 계속
        if let convertedChildren, convertedChildren.count == 1, hasNoInfo {
            let child = convertedChildren[0]
            // 자식의 types 앞에 현재 체인을 붙임
            return SimpleElement(
                types: newChain + child.types,
                label: child.label,
                identifier: child.identifier,
                value: child.value,
                placeholderValue: child.placeholderValue,
                frame: child.frame,
                children: child.children,
            )
        }

        let element = SimpleElement(
            types: newChain,
            label: label,
            identifier: identifier,
            value: value,
            placeholderValue: placeholderValue,
            frame: frame ?? .zero,
            children: convertedChildren,
        )

        // 정보가 없으면 제외
        if !element.hasInfo {
            return nil
        }

        return element
    }
}

// MARK: - SimpleElement 정보 판별

extension SimpleElement {
    /// 유의미한 정보가 있는지 판별
    var hasInfo: Bool {
        // label이 있으면 정보 있음
        if let label, !label.isEmpty { return true }
        // identifier가 있으면 정보 있음
        if let identifier, !identifier.isEmpty { return true }
        // value가 있으면 정보 있음
        if let value, !value.isEmpty { return true }
        // placeholderValue가 있으면 정보 있음
        if let placeholderValue, !placeholderValue.isEmpty { return true }
        // children이 있으면 정보 있음
        if let children, !children.isEmpty { return true }
        // 입력 가능한 타입은 정보가 없어도 유지
        if isInteractiveType { return true }
        return false
    }

    /// 입력 가능한 타입인지 판별 (정보가 없어도 유지해야 하는 타입)
    private var isInteractiveType: Bool {
        let interactiveTypes: Set<AXElementType> = [
            .textField,
            .secureTextField,
            .searchField,
            .textView,
        ]
        return types.contains { interactiveTypes.contains($0) }
    }

    /// 타입 체인에서 other 제거 (전부 other면 other 하나만 유지)
    var compactTypes: [AXElementType] {
        let filtered = types.filter { $0 != .other }
        return filtered.isEmpty ? [.other] : filtered
    }

    /// YAML 스타일로 보기 편한 문자열 변환
    public func toYAML(indent: Int = 0) -> String {
        var lines: [String] = []
        let prefix = String(repeating: "  ", count: indent)

        // 타입 체인 (other 제거)
        let typeStr = compactTypes.map(\.name).joined(separator: " > ")
        var header = "\(prefix)- \(typeStr)"

        // label, value, placeholderValue를 한 줄에 표시
        var attrs: [String] = []
        if let label, !label.isEmpty {
            attrs.append("label: \"\(label)\"")
        }
        if let value, !value.isEmpty {
            attrs.append("value: \"\(value)\"")
        }
        if let placeholderValue, !placeholderValue.isEmpty {
            attrs.append("placeholder: \"\(placeholderValue)\"")
        }
        if !attrs.isEmpty {
            header += " (\(attrs.joined(separator: ", ")))"
        }

        lines.append(header)

        // children 재귀
        if let children, !children.isEmpty {
            for child in children {
                lines.append(child.toYAML(indent: indent + 1))
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Array Extension

extension Array {
    var nilIfEmpty: Self? {
        isEmpty ? nil : self
    }
}
