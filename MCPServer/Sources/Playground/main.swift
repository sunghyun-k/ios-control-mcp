import Foundation
import IOSControlClient
import Common

// 커맨드라인 인수 파싱
let args = CommandLine.arguments

if args.count >= 2 && args[1] == "analyze" {
    print("=== 화면 밖 요소 분석 ===\n")

    let client = IOSControlClient()

    Task {
        do {
            // 1. 스크린샷 캡처
            print("📸 스크린샷 캡처 중...")
            let screenshotData = try await client.screenshot()
            let screenshotPath = "/tmp/ios_screenshot.png"
            try screenshotData.write(to: URL(fileURLWithPath: screenshotPath))
            print("✅ 스크린샷 저장: \(screenshotPath)\n")

            // 2. 화면 크기 확인 (상태에서)
            let status = try await client.status()
            print("📱 디바이스 상태:")
            print("  Status: \(status.status)")
            if let udid = status.udid {
                print("  UDID: \(udid)")
            }
            print()

            // 3. 포그라운드 앱 번들 ID 가져오기
            let foregroundApp = try await client.foregroundApp()
            let bundleId = foregroundApp.bundleId
            print("📱 포그라운드 앱: \(bundleId)\n")

            // 4. UI 트리 조회 (번들 ID 지정)
            print("🌳 UI 트리 조회 중...")
            let treeResponse = try await client.tree(appBundleId: bundleId)
            let tree = treeResponse.tree

            // 4. 화면 크기 (루트 요소에서)
            let screenWidth = tree.frame.width
            let screenHeight = tree.frame.height
            print("\n📐 화면 크기: \(Int(screenWidth)) x \(Int(screenHeight))\n")

            // 5. 트리 포맷 출력 (좌표 포함)
            print("=== 트리 출력 (좌표 포함) ===\n")
            let formatted = TreeFormatter.format(tree, showCoords: true)
            print(formatted)

            // 6. 화면 밖 요소 분석
            print("\n=== 화면 밖 요소 분석 ===\n")
            analyzeOffScreenElements(tree, screenWidth: screenWidth, screenHeight: screenHeight)


        } catch {
            print("❌ 에러: \(error.localizedDescription)")
        }
        exit(0)
    }

    RunLoop.main.run()
} else if args.count >= 3 && args[1] == "status" && args[2] == "--udid" {
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

// MARK: - 분석 함수들

/// 화면 밖 요소 분석
func analyzeOffScreenElements(_ element: AXElement, screenWidth: Double, screenHeight: Double, path: String = "root", results: inout [(path: String, element: AXElement, reason: String)]) {
    let frame = element.frame
    let centerX = frame.center.x
    let centerY = frame.center.y

    var reasons: [String] = []

    // 중심점이 화면 밖인지 확인
    if centerX < 0 {
        reasons.append("center.x < 0 (\(Int(centerX)))")
    }
    if centerX > screenWidth {
        reasons.append("center.x > screen (\(Int(centerX)) > \(Int(screenWidth)))")
    }
    if centerY < 0 {
        reasons.append("center.y < 0 (\(Int(centerY)))")
    }
    if centerY > screenHeight {
        reasons.append("center.y > screen (\(Int(centerY)) > \(Int(screenHeight)))")
    }

    // 프레임 전체가 화면 밖인지 확인
    if frame.x + frame.width < 0 {
        reasons.append("entirely left of screen")
    }
    if frame.x > screenWidth {
        reasons.append("entirely right of screen")
    }
    if frame.y + frame.height < 0 {
        reasons.append("entirely above screen")
    }
    if frame.y > screenHeight {
        reasons.append("entirely below screen")
    }

    // 라벨이나 타입이 있는 요소만 기록
    if !reasons.isEmpty && (!element.label.isEmpty || !["Other", "Window", "Group"].contains(element.type)) {
        results.append((path: path, element: element, reason: reasons.joined(separator: ", ")))
    }

    // 자식 요소 분석
    if let children = element.children {
        for (index, child) in children.enumerated() {
            let childPath = "\(path)/\(child.type)[\(index)]"
            analyzeOffScreenElements(child, screenWidth: screenWidth, screenHeight: screenHeight, path: childPath, results: &results)
        }
    }
}

func analyzeOffScreenElements(_ element: AXElement, screenWidth: Double, screenHeight: Double) {
    var results: [(path: String, element: AXElement, reason: String)] = []
    analyzeOffScreenElements(element, screenWidth: screenWidth, screenHeight: screenHeight, path: "root", results: &results)

    if results.isEmpty {
        print("✅ 화면 밖 요소 없음")
    } else {
        print("⚠️  화면 밖 요소 발견: \(results.count)개\n")
        for (_, element, reason) in results {
            let label = element.label.isEmpty ? "(no label)" : "\"\(element.label)\""
            print("• \(element.type) \(label)")
            print("  Frame: (\(Int(element.frame.x)), \(Int(element.frame.y))) \(Int(element.frame.width))x\(Int(element.frame.height))")
            print("  Center: (\(Int(element.frame.center.x)), \(Int(element.frame.center.y)))")
            print("  Reason: \(reason)")
            print("  enabled=\(element.enabled)")
            print()
        }
    }
}

