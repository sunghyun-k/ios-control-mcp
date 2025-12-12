import Foundation

/// xcodebuild 명령어 래핑 클라이언트
struct XcodeBuildClient: Sendable {
    /// 빌드 대상 유형
    enum BuildTarget: Sendable {
        /// Xcode 프로젝트 (.xcodeproj)
        case project(path: String)
        /// Xcode 워크스페이스 (.xcworkspace)
        case workspace(path: String)
    }

    /// 빌드 결과
    struct BuildResult: Sendable {
        /// .xctestrun 파일 경로
        let xctestrunPath: String
        /// derivedData 경로
        let derivedDataPath: String
    }

    init() {}

    // MARK: - Public

    /// 테스트용 빌드 (xcodebuild build-for-testing)
    /// - Parameters:
    ///   - target: 빌드 대상 (프로젝트 또는 워크스페이스)
    ///   - scheme: 스킴 이름
    ///   - deviceId: 대상 디바이스 UDID (시뮬레이터 또는 실제 기기)
    ///   - teamId: Apple Developer Team ID (실기기 빌드 시 필요)
    /// - Returns: 빌드 결과 (xctestrun 경로 포함)
    func buildForTesting(
        target: BuildTarget,
        scheme: String,
        deviceId: String,
        teamId: String? = nil,
    ) async throws -> BuildResult {
        let derivedDataPath = FileManager.default.temporaryDirectory
            .appending(path: "UIAutomationServer-\(UUID().uuidString)")
            .path

        var arguments = [
            "build-for-testing",
            "-scheme",
            scheme,
            "-destination",
            "id=\(deviceId)",
            "-derivedDataPath",
            derivedDataPath,
        ]

        // 빌드 대상에 따라 -project 또는 -workspace 추가
        switch target {
        case .project(let path):
            arguments.insert(contentsOf: ["-project", path], at: 1)
        case .workspace(let path):
            arguments.insert(contentsOf: ["-workspace", path], at: 1)
        }

        // Team ID가 있으면 코드 서명 설정 추가 (실기기용)
        if let teamId {
            arguments.append("DEVELOPMENT_TEAM=\(teamId)")
            arguments.append("CODE_SIGN_STYLE=Automatic")
        }

        try await runXcodebuild(arguments: arguments)

        // xctestrun 파일 찾기
        let xctestrunPath = try findXctestrun(derivedDataPath: derivedDataPath)

        return BuildResult(xctestrunPath: xctestrunPath, derivedDataPath: derivedDataPath)
    }

    /// 빌드 없이 테스트 실행 (xcodebuild test-without-building)
    /// - Parameters:
    ///   - xctestrunPath: .xctestrun 파일 경로
    ///   - deviceId: 대상 디바이스 UDID
    /// - Returns: 실행 중인 프로세스 (caller가 관리해야 함)
    func testWithoutBuilding(xctestrunPath: String, deviceId: String) throws -> Process {
        let arguments = [
            "test-without-building",
            "-xctestrun",
            xctestrunPath,
            "-destination",
            "id=\(deviceId)",
        ]

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/xcodebuild")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        return process
    }

    // MARK: - Private

    /// xcodebuild 실행 (완료까지 대기)
    private func runXcodebuild(arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
            Void,
            Error
        >) in
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/xcodebuild")
            process.arguments = arguments

            let errorPipe = Pipe()
            process.standardOutput = FileHandle.nullDevice
            process.standardError = errorPipe

            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: XcodeBuildError.buildFailed(
                        exitCode: process.terminationStatus,
                        message: errorMessage,
                    ))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// xctestrun 파일 찾기
    private func findXctestrun(derivedDataPath: String) throws -> String {
        let buildDir = "\(derivedDataPath)/Build/Products"
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(atPath: buildDir) else {
            throw XcodeBuildError.xctestrunNotFound(path: buildDir)
        }

        for file in contents where file.hasSuffix(".xctestrun") {
            return "\(buildDir)/\(file)"
        }

        throw XcodeBuildError.xctestrunNotFound(path: buildDir)
    }
}

// MARK: - Errors

enum XcodeBuildError: Error, LocalizedError {
    case buildFailed(exitCode: Int32, message: String)
    case xctestrunNotFound(path: String)

    var errorDescription: String? {
        switch self {
        case .buildFailed(let exitCode, let message):
            "Build failed (exit code: \(exitCode)): \(message)"
        case .xctestrunNotFound(let path):
            ".xctestrun file not found in: \(path)"
        }
    }
}
