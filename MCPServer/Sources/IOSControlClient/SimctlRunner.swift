import Foundation
import Common

/// simctl 명령 실행기
public struct SimctlRunner: Sendable {
    public static let shared = SimctlRunner()

    private let xcrunPath = "/usr/bin/xcrun"

    public init() {}

    // MARK: - 기본 실행

    /// simctl 명령 실행 (출력 무시)
    public func run(_ arguments: String...) throws {
        try run(arguments)
    }

    /// simctl 명령 실행 (출력 무시)
    public func run(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl"] + arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw IOSControlError.simctlError(
                command: arguments.first ?? "unknown",
                exitCode: process.terminationStatus
            )
        }
    }

    /// simctl 명령 실행 (출력 무시, 에러 무시)
    public func runIgnoringErrors(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl"] + arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try? process.run()
        process.waitUntilExit()
    }

    /// simctl 명령 실행 (출력 반환)
    public func runWithOutput(_ arguments: String...) throws -> String {
        try runWithOutput(arguments)
    }

    /// simctl 명령 실행 (출력 반환)
    public func runWithOutput(_ arguments: [String]) throws -> String {
        let data = try runWithData(arguments)
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// simctl 명령 실행 (Data 반환)
    public func runWithData(_ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl"] + arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        return pipe.fileHandleForReading.readDataToEndOfFile()
    }

    /// simctl 명령 실행 (stdin 입력 지원)
    public func runWithInput(_ arguments: [String], input: Data) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl"] + arguments

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        inputPipe.fileHandleForWriting.write(input)
        inputPipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw IOSControlError.simctlError(
                command: arguments.first ?? "unknown",
                exitCode: process.terminationStatus
            )
        }
    }

    // MARK: - 앱 관리

    /// 앱 설치
    public func installApp(deviceId: String, appPath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl", "install", deviceId, appPath]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw IOSControlError.simctlInstallFailed(exitCode: Int(process.terminationStatus))
        }
    }

    /// 앱 실행
    public func launchApp(deviceId: String, bundleId: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl", "launch", deviceId, bundleId]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw IOSControlError.simctlLaunchFailed(exitCode: Int(process.terminationStatus))
        }
    }

    /// 앱 종료 (실패해도 무시 - 이미 종료된 경우)
    public func terminateApp(deviceId: String, bundleId: String) {
        runIgnoringErrors(["terminate", deviceId, bundleId])
    }

    /// URL 열기
    public func openURL(deviceId: String, url: String) throws {
        try run("openurl", deviceId, url)
    }

    // MARK: - 클립보드

    /// 클립보드 읽기
    public func getPasteboard(deviceId: String) throws -> String {
        try runWithOutput("pbpaste", deviceId)
    }

    /// 클립보드 쓰기
    public func setPasteboard(deviceId: String, content: String) throws {
        guard let data = content.data(using: .utf8) else { return }
        try runWithInput(["pbcopy", deviceId], input: data)
    }

    // MARK: - 시뮬레이터 관리

    /// 시뮬레이터 부팅
    public func bootSimulator(deviceId: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl", "boot", deviceId]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        // exit code 149는 이미 부팅된 상태
        if process.terminationStatus != 0 && process.terminationStatus != 149 {
            throw IOSControlError.simulatorBootFailed(
                udid: deviceId,
                exitCode: Int(process.terminationStatus)
            )
        }
    }

    /// 부팅된 시뮬레이터 목록 조회
    public func getBootedSimulators() -> [String] {
        guard let output = try? runWithOutput("list", "devices", "booted", "-j"),
              let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }

        var bootedIds: [String] = []
        for (_, deviceList) in devices {
            for device in deviceList {
                if device["state"] as? String == "Booted",
                   let udid = device["udid"] as? String {
                    bootedIds.append(udid)
                }
            }
        }
        return bootedIds
    }

    /// 디바이스 목록 조회 (JSON)
    public func listDevicesJSON() throws -> Data {
        try runWithData(["list", "devices", "-j"])
    }

    /// 설치된 앱 목록 조회 (plist → JSON 변환)
    public func listApps(deviceId: String) throws -> [[String: Any]] {
        let plistData = try runWithData(["listapps", deviceId])

        guard let plist = try PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        ) as? [String: [String: Any]] else {
            return []
        }

        return plist.map { (bundleId, info) in
            var appInfo = info
            appInfo["CFBundleIdentifier"] = bundleId
            return appInfo
        }
    }
}
