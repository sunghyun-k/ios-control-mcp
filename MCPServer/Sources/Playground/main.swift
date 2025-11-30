import Foundation
import IOSControlClient

// 커맨드라인 인수 파싱
let args = CommandLine.arguments

if args.count >= 3 && args[1] == "status" && args[2] == "--udid" {
    let udid = args[3]
    print("=== USB HTTP 통신 테스트 ===\n")
    print("UDID: \(udid)\n")

    let client = USBHTTPClient(udid: udid)

    Task {
        do {
            let status = try await client.status()
            print("✅ 연결 성공!")
            print("  Status: \(status.status)")
            if let udid = status.udid {
                print("  UDID: \(udid)")
            }
        } catch {
            print("❌ 연결 실패: \(error.localizedDescription)")
        }
        exit(0)
    }

    RunLoop.main.run()
} else {
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
}
