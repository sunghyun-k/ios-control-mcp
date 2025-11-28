import Foundation
import IOSControlClient

let client = IOSControlClient()

func printUsage() {
    print("""
    Usage: Playground <command> [args...]

    Commands:
      status              서버 상태 확인
      list-apps           설치된 앱 목록 조회
      launch <bundle_id>  앱 실행
      home                홈으로 이동
      foreground          포그라운드 앱 조회
      tree                UI 트리 조회
      tap <x> <y>         좌표 탭
      screenshot [path]   스크린샷 저장 (기본: screenshot.png)
    """)
}

func run() async throws {
    let args = Array(CommandLine.arguments.dropFirst())

    guard let command = args.first else {
        printUsage()
        return
    }

    switch command {
    case "status":
        let response = try await client.status()
        print("Status: \(response.status)")

    case "list-apps":
        let response = try await client.listApps()
        print("Installed apps (\(response.bundleIds.count)):")
        for bundleId in response.bundleIds {
            print("  - \(bundleId)")
        }

    case "launch":
        guard args.count >= 2 else {
            print("Error: bundle_id required")
            return
        }
        let bundleId = args[1]
        try await client.launchApp(bundleId: bundleId)
        print("Launched: \(bundleId)")

    case "home":
        try await client.goHome()
        print("Pressed home button")

    case "foreground":
        let response = try await client.foregroundApp()
        if let bundleId = response.bundleId {
            print("Foreground app: \(bundleId)")
        } else {
            print("No foreground app (home screen)")
        }

    case "tree":
        let response = try await client.tree()
        print(TreeFormatter.format(response.tree, showCoords: false))

    case "tap":
        guard args.count >= 3,
              let x = Double(args[1]),
              let y = Double(args[2]) else {
            print("Error: tap <x> <y>")
            return
        }
        try await client.tap(x: x, y: y)
        print("Tapped: (\(x), \(y))")

    case "screenshot":
        let path = args.count >= 2 ? args[1] : "screenshot.png"
        let data = try await client.screenshot()
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        print("Screenshot saved: \(url.path)")

    default:
        print("Unknown command: \(command)")
        printUsage()
    }
}

do {
    try await run()
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
