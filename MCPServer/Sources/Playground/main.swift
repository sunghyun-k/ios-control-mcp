import Foundation
import IOSControlClient

let client = IOSControlClient()
let outputDir = "/tmp/ios-control-test"

// 출력 디렉토리 생성
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

print("=== 새 기능 테스트 (검증 포함) ===")
print("출력 디렉토리: \(outputDir)\n")

// 1. 클립보드 테스트
print("1. 클립보드 테스트")
let testText = "Test_\(Int.random(in: 1000...9999))"
try await client.setPasteboard(testText)
let pasteboard = try await client.getPasteboard()
let clipboardMatch = pasteboard.content == testText
print("   설정: \"\(testText)\"")
print("   읽기: \"\(pasteboard.content ?? "nil")\"")
print("   결과: \(clipboardMatch ? "✅ 일치" : "❌ 불일치")")

// 2. openURL 테스트
print("\n2. openURL 테스트")
try await client.openURL("https://www.apple.com")
try await Task.sleep(for: .seconds(1))
let foregroundAfterURL = try await client.foregroundApp()
let safariOpened = foregroundAfterURL.bundleId == "com.apple.mobilesafari"
print("   포그라운드: \(foregroundAfterURL.bundleId ?? "nil")")
print("   결과: \(safariOpened ? "✅ Safari 열림" : "❌ Safari 아님")")

// 3. launchApp/terminateApp 테스트
print("\n3. launchApp/terminateApp 테스트")
try await client.launchApp(bundleId: "com.apple.Preferences")
try await Task.sleep(for: .seconds(1))
let foregroundAfterLaunch = try await client.foregroundApp()
let appLaunched = foregroundAfterLaunch.bundleId == "com.apple.Preferences"
print("   launchApp 후: \(foregroundAfterLaunch.bundleId ?? "nil")")
print("   결과: \(appLaunched ? "✅ 설정 앱 실행됨" : "❌ 실행 실패")")

try await client.terminateApp(bundleId: "com.apple.Preferences")
try await Task.sleep(for: .seconds(0.5))
let foregroundAfterTerminate = try await client.foregroundApp()
let appTerminated = foregroundAfterTerminate.bundleId != "com.apple.Preferences"
print("   terminateApp 후: \(foregroundAfterTerminate.bundleId ?? "nil")")
print("   결과: \(appTerminated ? "✅ 설정 앱 종료됨" : "❌ 종료 실패")")

// 4. 핀치 테스트 - 스크린샷 저장
print("\n4. 핀치 테스트 (지도 앱)")
try await client.launchApp(bundleId: "com.apple.Maps")
try await Task.sleep(for: .seconds(2))

// 줌 전 스크린샷 저장
let beforePath = "\(outputDir)/pinch_before.png"
let beforePinch = try await client.screenshot()
try beforePinch.write(to: URL(fileURLWithPath: beforePath))
print("   줌 전: \(beforePath) (\(beforePinch.count) bytes)")

// 줌 인
try await client.pinch(x: 200, y: 400, scale: 2.0, velocity: 1.0)
try await Task.sleep(for: .seconds(1))

// 줌 후 스크린샷 저장
let afterPath = "\(outputDir)/pinch_after.png"
let afterPinch = try await client.screenshot()
try afterPinch.write(to: URL(fileURLWithPath: afterPath))
print("   줌 후: \(afterPath) (\(afterPinch.count) bytes)")

let sizeDiff = afterPinch.count - beforePinch.count
let diffPercent = Double(sizeDiff) / Double(beforePinch.count) * 100
print("   크기 변화: \(sizeDiff > 0 ? "+" : "")\(sizeDiff) bytes (\(String(format: "%.1f", diffPercent))%)")

try await client.terminateApp(bundleId: "com.apple.Maps")

print("\n=== 테스트 완료 ===")
print("스크린샷 확인: \(outputDir)/pinch_*.png")
