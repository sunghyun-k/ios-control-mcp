import Foundation
import IOSControlClient

print("=== 실기기 USB 연결 테스트 ===\n")

// 1. 기기 목록 확인
let devices = try await DeviceManager.shared.listAllDevices()

let physicals = devices.filter { $0.type == .physical }

print("연결된 실기기: \(physicals.count)개")

guard let physicalDevice = physicals.first else {
    print("❌ 연결된 실기기가 없습니다.")
    print("   USB로 iOS 기기를 연결하세요.")
    exit(1)
}

print("✓ 실기기 발견: \(physicalDevice.id)")

// 2. USB 기기 정보 확인
if let usbInfo = await DeviceManager.shared.getPhysicalDeviceInfo(udid: physicalDevice.id) {
    print("  - DeviceID: \(usbInfo.deviceID)")
    print("  - ConnectionType: \(usbInfo.connectionType)")
    if let productID = usbInfo.productID {
        print("  - ProductID: \(productID)")
    }
}

// 3. USB HTTP 클라이언트로 Agent 연결 시도
print("\n--- Agent 연결 테스트 ---")

do {
    let usbClient = try await DeviceManager.shared.getUSBHTTPClient(udid: physicalDevice.id)

    print("Agent 상태 확인 중...")
    let status = try await usbClient.status()
    print("✓ Agent 연결 성공!")
    print("  - UDID: \(status.udid ?? "N/A")")

    // 4. UI Tree 조회
    print("\nUI Tree 조회 중...")
    let tree = try await usbClient.tree()
    let treeString = TreeFormatter.format(tree.tree, showCoords: false)

    print("✓ UI Tree 조회 성공!")
    print(treeString)

} catch USBHTTPError.httpError(let code) {
    print("❌ HTTP 에러: \(code)")
} catch {
    print("❌ Agent 연결 실패: \(error)")
    print("")
    print("실기기에서 Agent가 실행 중이지 않습니다.")
    print("다음 명령어로 Agent를 실행하세요:")
    print("")
    print("  make device-agent TEAM=<YOUR_TEAM_ID>")
    print("  make device-agent-run TEAM=<YOUR_TEAM_ID> DEVICE_UDID=\(physicalDevice.id)")
}

print("\n=== 테스트 완료 ===")
