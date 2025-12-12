import Foundation

/// simctl 명령어 래핑 클라이언트
struct SimulatorControlClient: Sendable {
    private let xcrunPath = "/usr/bin/xcrun"

    init() {}

    // MARK: - 시뮬레이터 조회

    /// 부팅된 시뮬레이터 UDID 목록 반환
    func bootedSimulatorIds() throws -> [String] {
        let data = try runSimctl(["list", "devices", "booted", "-j"])
        let response = try JSONDecoder().decode(SimctlDeviceListResponse.self, from: data)

        return response.devices.values
            .flatMap(\.self)
            .filter(\.isBooted)
            .map(\.udid)
    }

    /// 모든 시뮬레이터 목록 반환
    func allSimulators() throws -> [Simulator] {
        let data = try runSimctl(["list", "devices", "-j"])
        let response = try JSONDecoder().decode(SimctlDeviceListResponse.self, from: data)

        var simulators: [Simulator] = []
        for (runtimeId, deviceList) in response.devices {
            for var simulator in deviceList {
                simulator.runtimeId = runtimeId
                simulators.append(simulator)
            }
        }
        return simulators
    }

    // MARK: - 시뮬레이터 제어

    /// 시뮬레이터 부팅
    func boot(simulatorId: String) throws {
        do {
            try runSimctlIgnoreOutput(["boot", simulatorId])
        } catch let error as SimulatorError {
            // exit code 149는 이미 부팅된 상태
            if case .commandFailed(_, let exitCode, _) = error, exitCode == 149 {
                return
            }
            throw error
        }
    }

    /// 시뮬레이터 종료
    func shutdown(simulatorId: String) throws {
        try runSimctlIgnoreOutput(["shutdown", simulatorId])
    }

    // MARK: - Private

    private func runSimctl(_ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(filePath: xcrunPath)
        process.arguments = ["simctl"] + arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw SimulatorError.commandFailed(
                command: "simctl \(arguments.joined(separator: " "))",
                exitCode: process.terminationStatus,
                message: nil,
            )
        }

        return pipe.fileHandleForReading.readDataToEndOfFile()
    }

    private func runSimctlIgnoreOutput(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(filePath: xcrunPath)
        process.arguments = ["simctl"] + arguments
        process.standardOutput = FileHandle.nullDevice

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8)
            throw SimulatorError.commandFailed(
                command: "simctl \(arguments.joined(separator: " "))",
                exitCode: process.terminationStatus,
                message: errorMessage,
            )
        }
    }
}

// MARK: - Models

/// simctl list devices -j 응답 구조
private struct SimctlDeviceListResponse: Decodable {
    let devices: [String: [Simulator]]
}

struct Simulator: Sendable, Decodable {
    let udid: String
    let name: String
    let state: String
    /// 런타임 ID (디코딩 후 설정됨)
    fileprivate(set) var runtimeId: String = ""
    let isAvailable: Bool

    var isBooted: Bool {
        state == "Booted"
    }

    /// 런타임 ID에서 iOS 버전 추출 (예: "com.apple.CoreSimulator.SimRuntime.iOS-18-0" -> "18.0")
    var iosVersion: String? {
        guard let range = runtimeId.range(of: "iOS-") else { return nil }
        let versionPart = String(runtimeId[range.upperBound...])
        return versionPart.replacingOccurrences(of: "-", with: ".")
    }

    private enum CodingKeys: String, CodingKey {
        case udid, name, state, isAvailable
    }
}

// MARK: - Errors

enum SimulatorError: Error, LocalizedError {
    case commandFailed(command: String, exitCode: Int32, message: String?)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let exitCode, let message):
            var desc = "Command '\(command)' failed with exit code \(exitCode)"
            if let message, !message.isEmpty {
                desc += ": \(message)"
            }
            return desc
        }
    }
}
