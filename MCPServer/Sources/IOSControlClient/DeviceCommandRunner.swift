import Foundation

/// 기기 명령 실행 프로토콜
/// 시뮬레이터와 실기기 모두에서 사용할 수 있는 공통 인터페이스
public protocol DeviceCommandRunner: Sendable {
    /// 기기 타입
    var deviceType: DeviceType { get }

    // MARK: - 기기 목록

    /// 연결된 기기 목록 조회
    func listDevices() throws -> [DeviceInfo]

    // MARK: - 앱 관리

    /// 앱 설치
    func installApp(deviceId: String, appPath: String) throws

    /// 앱 실행
    func launchApp(deviceId: String, bundleId: String) throws

    /// 설치된 앱 목록 조회
    func listApps(deviceId: String) throws -> [[String: Any]]
}

// MARK: - SimctlRunner Extension

extension SimctlRunner: DeviceCommandRunner {
    public var deviceType: DeviceType { .simulator }

    public func listDevices() throws -> [DeviceInfo] {
        let data = try listDevicesJSON()

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }

        var result: [DeviceInfo] = []

        for (runtime, deviceList) in devices {
            // iOS 런타임만 필터링 (watchOS, tvOS 제외)
            guard runtime.contains("iOS") else { continue }

            // 버전 추출 (예: "com.apple.CoreSimulator.SimRuntime.iOS-17-0" → "17.0")
            let osVersion = extractIOSVersion(from: runtime)

            for device in deviceList {
                guard let udid = device["udid"] as? String,
                      let name = device["name"] as? String,
                      let state = device["state"] as? String else {
                    continue
                }

                // iPhone만 필터링
                guard name.contains("iPhone") else { continue }

                let isBooted = state == "Booted"

                result.append(DeviceInfo(
                    id: udid,
                    name: name,
                    type: .simulator,
                    isConnected: isBooted,
                    osVersion: osVersion,
                    model: device["deviceTypeIdentifier"] as? String
                ))
            }
        }

        // 부팅된 기기를 먼저, 그 다음 이름순
        return result.sorted { lhs, rhs in
            if lhs.isConnected != rhs.isConnected {
                return lhs.isConnected
            }
            return lhs.name < rhs.name
        }
    }

    /// iOS 버전 추출
    private func extractIOSVersion(from runtime: String) -> String? {
        // "com.apple.CoreSimulator.SimRuntime.iOS-17-0" → "17.0"
        guard let range = runtime.range(of: "iOS-") else { return nil }
        let versionPart = runtime[range.upperBound...]
        return versionPart.replacingOccurrences(of: "-", with: ".")
    }
}
