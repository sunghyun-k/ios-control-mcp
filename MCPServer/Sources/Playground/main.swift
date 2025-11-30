import Foundation
import IOSControlClient

print("=== devicectl 기기 목록 테스트 ===\n")

do {
    let devices = try DeviceCtlRunner.shared.listDevices()

    if devices.isEmpty {
        print("연결된 실기기가 없습니다.")
    } else {
        print("연결된 실기기: \(devices.count)개\n")
        for device in devices {
            print("- \(device.name) (\(device.hardwareUdid))")
            if let os = device.osVersion {
                print("  \(device.platform) \(os)")
            }
            print("  Model: \(device.model)")
            print("  Connection: \(device.transportType) (\(device.connectionState))")
            print()
        }
    }
} catch {
    print("에러: \(error)")
}

print("=== 테스트 완료 ===")
