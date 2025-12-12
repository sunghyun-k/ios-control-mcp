import Foundation
import iOSAutomation
import Testing

@Suite("iOSAutomation 통합 테스트")
struct iOSAutomationTests {
    let automation = iOSAutomation()

    // MARK: - health

    @Test("health - 서버 상태 확인")
    func health() async throws {
        let isHealthy = try await automation.health()
        #expect(isHealthy)
    }

    // MARK: - launchApp

    @Test("launchApp - 앱 실행")
    func launchApp() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        let bundleIds = try await automation.foregroundAppBundleIds()
        #expect(bundleIds.contains("com.apple.Preferences"))
    }

    // MARK: - foregroundAppBundleIds

    @Test("foregroundAppBundleIds - foreground 앱 목록 반환")
    func foregroundAppBundleIds() async throws {
        let bundleIds = try await automation.foregroundAppBundleIds()

        // 스프링보드는 항상 포함
        #expect(bundleIds.contains("com.apple.springboard"))
        // 최소 1개 이상
        #expect(!bundleIds.isEmpty)
    }

    // MARK: - snapshot

    @Test("snapshot - 모든 foreground 앱 스냅샷 반환")
    func snapshot() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        let snapshots = try await automation.snapshot()

        // 설정 앱 스냅샷 존재
        #expect(snapshots["com.apple.Preferences"] != nil)

        // 스냅샷이 비어있지 않음
        let settingsSnapshot = snapshots["com.apple.Preferences"]!
        #expect(!settingsSnapshot.toYAML().isEmpty)
    }

    // MARK: - screenshot

    @Test("screenshot - 스크린샷 가져오기")
    func screenshot() async throws {
        let data = try await automation.screenshot()

        // PNG 이미지 데이터인지 확인 (PNG 매직 넘버)
        #expect(data.count > 8)
        #expect(data[0] == 0x89)
        #expect(data[1] == 0x50) // P
        #expect(data[2] == 0x4E) // N
        #expect(data[3] == 0x47) // G
    }

    // MARK: - tapByLabel

    @Test("tapByLabel - label로 요소 탭")
    func tapByLabel() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        // "일반" 탭
        try await automation.tapByLabel("일반")
        try await Task.sleep(for: .milliseconds(500))

        // 스냅샷에서 "일반" 화면인지 확인 (소프트웨어 업데이트 등이 보여야 함)
        let snapshots = try await automation.snapshot()
        let yaml = snapshots["com.apple.Preferences"]!.toYAML()
        #expect(yaml.contains("소프트웨어 업데이트") || yaml.contains("Software Update"))

        // 뒤로 가기
        try await automation.tapByLabel("설정")
    }

    // MARK: - tapAtPoint

    @Test("tapAtPoint - 좌표로 탭")
    func tapAtPoint() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        // 화면 중앙 부근 탭 (설정 앱에서 어떤 항목이든 탭)
        try await automation.tapAtPoint(x: 200, y: 300)
        try await Task.sleep(for: .milliseconds(300))

        // 탭 후 앱이 여전히 foreground에 있는지 확인
        let bundleIds = try await automation.foregroundAppBundleIds()
        #expect(bundleIds.contains("com.apple.Preferences"))

        // 설정 앱 재실행으로 초기화
        try await automation.launchApp(bundleId: "com.apple.Preferences")
    }

    // MARK: - typeText

    @Test("typeText - 검색창에 텍스트 입력")
    func typeText() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        // 검색창 탭
        try await automation.tapByLabel("검색")
        try await Task.sleep(for: .milliseconds(300))

        // 텍스트 입력
        try await automation.typeText("Wi-Fi")
        try await Task.sleep(for: .milliseconds(500))

        // 스냅샷에서 검색 결과 확인
        let snapshots = try await automation.snapshot()
        let yaml = snapshots["com.apple.Preferences"]!.toYAML()
        #expect(yaml.contains("Wi-Fi"))

        // 설정 앱 재실행으로 초기화
        try await automation.launchApp(bundleId: "com.apple.Preferences")
    }

    // MARK: - dragByLabel

    @Test("dragByLabel - 언어 순서 드래그")
    func dragByLabel() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        // 일반 탭
        try await automation.tapByLabel("일반")
        try await Task.sleep(for: .milliseconds(500))

        // 언어 및 지역 탭
        try await automation.tapByLabel("언어 및 지역")
        try await Task.sleep(for: .milliseconds(500))

        // 한국어 드래그 핸들을 영어로 드래그
        try await automation.dragByLabel(
            sourceLabel: "한국어 재정렬",
            targetLabel: "English 재정렬",
        )
        try await Task.sleep(for: .milliseconds(500))

        // 언어 변경 시 재시동 알림이 뜨면 취소 선택
        do {
            try await automation.tapByLabel("취소")
        } catch {
            // 알림이 안 뜨면 무시
        }

        // 뒤로 가기 (일반으로)
        try await automation.tapByLabel("일반")
        try await Task.sleep(for: .milliseconds(300))

        // 뒤로 가기 (설정으로)
        try await automation.tapByLabel("설정")
    }

    // MARK: - swipeByLabel

    @Test("swipeByLabel - 스와이프")
    func swipeByLabel() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        // 아래로 스와이프
        try await automation.swipeByLabel(direction: .up)
        try await Task.sleep(for: .milliseconds(300))

        // 스와이프 후 앱이 여전히 foreground에 있는지 확인
        let bundleIds = try await automation.foregroundAppBundleIds()
        #expect(bundleIds.contains("com.apple.Preferences"))

        // 위로 스와이프하여 원래 위치로
        try await automation.swipeByLabel(direction: .down)
    }

    // MARK: - pressButton

    @Test("pressButton - 하드웨어 버튼")
    func pressButton() async throws {
        try await automation.launchApp(bundleId: "com.apple.Preferences")
        try await Task.sleep(for: .milliseconds(500))

        // 홈 버튼 누르기
        try await automation.pressButton(.home)
        try await Task.sleep(for: .milliseconds(500))

        // 홈 화면으로 이동했는지 확인 (스프링보드가 foreground)
        let bundleIds = try await automation.foregroundAppBundleIds()
        #expect(bundleIds.first == "com.apple.springboard" || bundleIds
            .contains("com.apple.springboard"))
    }
}
