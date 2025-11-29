import Foundation
import IOSControlClient

print("=== 실기기 자동 빌드/실행 테스트 ===\n")

// 1. 환경변수 확인
let teamId = ProcessInfo.processInfo.environment["IOS_CONTROL_TEAM_ID"]
print("IOS_CONTROL_TEAM_ID: \(teamId ?? "(not set)")")

// 2. 기기 목록 확인
let devices = try await DeviceManager.shared.listAllDevices()
let physicals = devices.filter { $0.type == .physical }

print("연결된 실기기: \(physicals.count)개")

guard let physicalDevice = physicals.first else {
    print("❌ 연결된 실기기가 없습니다.")
    print("   USB로 iOS 기기를 연결하세요.")
    exit(1)
}

print("✓ 실기기 발견: \(physicalDevice.id)")

// 3. 실기기 선택 및 클라이언트 획득 테스트
print("\n--- 실기기 클라이언트 테스트 ---")
print("실기기 선택: \(physicalDevice.id)")

do {
    // 실기기 명시적 선택
    try await DeviceManager.shared.selectDevice(udid: physicalDevice.id)
    let client = try await DeviceManager.shared.getAgentClient()
    print("✓ 클라이언트 획득 성공: \(type(of: client))")

    // 서버 상태 확인 (이 시점에서 자동 빌드/실행됨)
    print("\nAgent 서버 상태 확인 중...")
    print("(xctestrun이 없으면 자동으로 빌드합니다)")

    let isRunning = await client.isServerRunning()
    if isRunning {
        print("✓ Agent 서버 실행 중")

        let status = try await client.status()
        print("  - UDID: \(status.udid ?? "N/A")")

        // UI Tree 조회
        print("\nUI Tree 조회 중...")
        let tree = try await client.tree()
        let treeString = TreeFormatter.format(tree.tree, showCoords: false)
        print("✓ UI Tree 조회 성공!")
        print(treeString)
    } else {
        print("❌ Agent 서버가 실행 중이지 않습니다.")
    }

} catch {
    print("❌ 에러: \(error.localizedDescription)")
}

print("\n=== 테스트 완료 ===")
