import Foundation
import IOSControlClient

print("=== 실기기 감지 테스트 ===\n")

let deviceManager = DeviceManager()

// listAllDevices 호출 시 자동으로 USB 리스닝 시작
print("기기 목록 조회 중...")
let devices = try await deviceManager.listAllDevices()

print("\n전체 기기 목록:")
let simulators = devices.filter { $0.type == .simulator && $0.isConnected }
let physicals = devices.filter { $0.type == .physical }

print("  부팅된 시뮬레이터: \(simulators.count)개")
print("  실기기: \(physicals.count)개")

print("\n=== 연결된 기기 ===")
for device in simulators + physicals {
    let typeStr = device.type == .simulator ? "Simulator" : "Physical"
    print("[\(typeStr)] \(device.name)")
    print("  UDID: \(device.id)")
    if let os = device.osVersion {
        print("  iOS: \(os)")
    }
}

print("\n=== 테스트 완료 ===")
