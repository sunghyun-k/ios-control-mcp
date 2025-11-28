import Foundation
import IOSControlClient

let client = IOSControlClient()

// MARK: - Playground: 테스트하고 싶은 코드 작성

// 앱 목록 조회
let apps = try await client.listApps()
print("설치된 앱 (\(apps.bundleIds.count)개):")
for bundleId in apps.bundleIds {
    print("  - \(bundleId)")
}

// 설정 앱 실행
print("\n설정 앱 실행...")
try await client.launchApp(bundleId: "com.apple.Preferences")
print("완료!")
