import Foundation
import IOSControlClient

print("=== devicectl 매핑 테스트 ===\n")

// 1. devicectl 직접 조회
print("--- devicectl 기기 목록 ---")
do {
    let deviceCtlDevices = try DeviceCtlRunner.shared.listDevices()
    for device in deviceCtlDevices {
        print("CoreDevice ID: \(device.coreDeviceId)")
        print("Hardware UDID: \(device.hardwareUdid)")
        print("Name: \(device.name)")
        print("Model: \(device.model)")
        print("OS: \(device.osVersion ?? "N/A")")
        print("Transport: \(device.transportType)")
        print("Connected: \(device.isConnected)")
        print()
    }
} catch {
    print("devicectl 에러: \(error)")
}

// 2. DeviceManager 통합 조회 (devicectl + usbmuxd 매핑)
print("\n--- DeviceManager 통합 기기 목록 ---")
let devices = try await DeviceManager.shared.listAllDevices()
let physicals = devices.filter { $0.type == .physical }

print("연결된 실기기: \(physicals.count)개")
for device in physicals {
    print("ID: \(device.id)")
    print("Name: \(device.name)")
    print("Model: \(device.model ?? "N/A")")
    print("OS: \(device.osVersion ?? "N/A")")
    print("Connected: \(device.isConnected)")
    print()
}

print("\n=== 테스트 완료 ===")
