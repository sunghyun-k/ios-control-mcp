import Common
import Foundation

// MARK: - AXSnapshot Extensions

extension AXSnapshot {
    /// elementType을 AXElementType enum으로 변환
    var type: AXElementType? {
        guard let elementType else { return nil }
        return AXElementType(rawValue: elementType)
    }

    /// 모든 자손 요소를 평탄화하여 반환
    func flattened() -> [AXSnapshot] {
        var result = [self]
        if let children {
            for child in children {
                result.append(contentsOf: child.flattened())
            }
        }
        return result
    }

    /// 조건에 맞는 요소 찾기
    func find(where predicate: (AXSnapshot) -> Bool) -> [AXSnapshot] {
        flattened().filter(predicate)
    }

    /// label로 요소 찾기
    func findByLabel(_ label: String) -> [AXSnapshot] {
        find { $0.label == label }
    }

    /// identifier로 요소 찾기
    func findByIdentifier(_ identifier: String) -> [AXSnapshot] {
        find { $0.identifier == identifier }
    }

    /// elementType으로 요소 찾기
    func findByType(_ type: AXElementType) -> [AXSnapshot] {
        find { $0.elementType == type.rawValue }
    }

    /// 스프링보드에서 foreground 앱 번들 ID들 추출
    func foregroundAppBundleIds() -> [String] {
        // identifier가 "card:<bundleId>:sceneID:..." 패턴인 요소들 찾기
        let cardElements = find(where: { $0.identifier?.hasPrefix("card:") == true })

        return cardElements.compactMap { element -> String? in
            guard let identifier = element.identifier else { return nil }
            // "card:com.apple.Preferences:sceneID:..." -> "com.apple.Preferences"
            let parts = identifier.split(separator: ":")
            guard parts.count >= 2 else { return nil }
            return String(parts[1])
        }
    }
}

// MARK: - AXFrame Extension

extension AXFrame {
    /// 기본값 (0, 0, 0, 0)
    static let zero = AXFrame(x: 0, y: 0, width: 0, height: 0)
}
