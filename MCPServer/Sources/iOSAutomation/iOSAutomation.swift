@_exported import Common
import Foundation

/// 환경변수 키
public enum iOSAutomationEnv {
    /// 워크스페이스 경로
    public static let workspacePath = "IOS_CONTROL_WORKSPACE_PATH"
    /// Apple Developer Team ID (실기기용)
    public static let teamId = "IOS_CONTROL_TEAM_ID"
}

/// iOS 디바이스 자동화
/// 번들 ID를 몰라도 foreground 앱들을 자동 순회하며 UI 조작 수행
/// 시뮬레이터와 실기기 모두 지원 (먼저 selectDevice로 기기 선택 필요)
public final class iOSAutomation: @unchecked Sendable {
    private let deviceManager = DeviceManager()
    private let serverLauncher: AutomationServerLauncher
    private var cachedClient: UIAutomationClient?
    private var cachedDeviceId: String?

    /// 현재 선택된 기기
    private var _selectedDevice: DeviceInfo?

    public init() {
        serverLauncher = AutomationServerLauncher(workspacePath: Self.findWorkspacePath())
    }

    // MARK: - Private - 경로 탐색

    /// 워크스페이스 경로 찾기
    private static func findWorkspacePath() -> String {
        let fm = FileManager.default

        // 1. 환경변수 확인
        if let envPath = ProcessInfo.processInfo.environment[iOSAutomationEnv.workspacePath],
           fm.fileExists(atPath: envPath)
        {
            return envPath
        }

        // 2. 실행파일 디렉토리 기준
        let executableDir = URL(filePath: CommandLine.arguments[0])
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        return executableDir.appending(path: "iOSControlMCP.xcworkspace").path
    }

    // MARK: - 기기 관리

    /// 사용 가능한 모든 기기 목록 반환
    public func listDevices() throws -> [DeviceInfo] {
        try deviceManager.listAllDevices()
    }

    /// 기기 선택 및 서버 연결 수립 (UDID로)
    /// 시뮬레이터/실기기 모두 UIAutomationServer 자동 실행
    public func selectDevice(udid: String) async throws {
        let devices = try deviceManager.listAllDevices()
        guard let device = devices.first(where: { $0.id == udid }) else {
            throw DeviceSelectionError.deviceNotFound(udid)
        }

        // 기존 서버 정리
        serverLauncher.stop()

        _selectedDevice = device
        // 캐시 초기화 (기기 변경 시)
        cachedClient = nil
        cachedDeviceId = nil

        // 서버 시작
        try await serverLauncher.start(device: device)
    }

    /// 현재 선택된 기기 반환
    public var selectedDevice: DeviceInfo? {
        _selectedDevice
    }

    // MARK: - 클라이언트 획득

    /// 현재 선택된 기기에 맞는 클라이언트 반환
    /// selectDevice()로 먼저 기기를 선택해야 함 (서버도 그때 시작됨)
    private func getClient() throws -> UIAutomationClient {
        guard let device = _selectedDevice else {
            throw DeviceSelectionError.noDeviceSelected
        }

        // 캐시된 클라이언트가 있고 같은 기기면 재사용
        if let cached = cachedClient, cachedDeviceId == device.id {
            return cached
        }

        // Transport 선택 (서버는 selectDevice에서 이미 시작됨)
        let transport: any HTTPTransport = switch device.type {
        case .simulator:
            URLSessionTransport()
        case .physical:
            USBMuxTransport(udid: device.id)
        }

        let client = UIAutomationClient(transport: transport)
        cachedClient = client
        cachedDeviceId = device.id
        return client
    }

    // MARK: - 서버 상태

    /// 서버 상태 확인
    public func health() async throws -> Bool {
        let client = try getClient()
        return try await client.health()
    }

    // MARK: - 앱 관리

    /// 앱 실행
    public func launchApp(bundleId: String) async throws {
        let client = try getClient()
        try await client.launchApp(bundleId: bundleId)
    }

    /// 현재 foreground에 있는 앱들의 번들 ID 목록 반환
    public func foregroundAppBundleIds() async throws -> [String] {
        let client = try getClient()
        let springboardSnapshot = try await client.snapshot(bundleId: "com.apple.springboard")
        let rawBundleIds = springboardSnapshot.foregroundAppBundleIds()

        // 중복 제거 (순서 유지)
        var uniqueBundleIds = rawBundleIds.reduce(into: [String]()) { result, id in
            if !result.contains(id) {
                result.append(id)
            }
        }

        uniqueBundleIds.append("com.apple.springboard")
        return uniqueBundleIds
    }

    // MARK: - 스냅샷/스크린샷

    /// 모든 foreground 앱의 UI 스냅샷을 SimpleElement로 변환하여 반환
    public func snapshot() async throws -> [String: SimpleElement] {
        let client = try getClient()
        let bundleIds = try await foregroundAppBundleIds()

        return try await withThrowingTaskGroup(of: (String, SimpleElement?).self) { group in
            for bundleId in bundleIds {
                group.addTask {
                    let axSnapshot = try await client.snapshot(bundleId: bundleId)
                    return (bundleId, axSnapshot.toSimpleElement())
                }
            }

            var result: [String: SimpleElement] = [:]
            for try await (bundleId, element) in group {
                if let element {
                    result[bundleId] = element
                }
            }
            return result
        }
    }

    /// 화면 스크린샷 가져오기 (PNG 이미지 데이터)
    public func screenshot() async throws -> Data {
        let client = try getClient()
        return try await client.screenshot()
    }

    // MARK: - 탭

    /// label로 요소 탭
    public func tapByLabel(_ label: String, elementType: AXElementType? = nil) async throws {
        let client = try getClient()
        let target = ElementTarget(elementType: elementType, selector: .label(label))
        try await tryOnForegroundApps(
            client: client,
            onAllFailed: TapError.elementNotFound(label: label),
        ) { bundleId in
            try await client.tap(bundleId: bundleId, element: target)
        }
    }

    /// 좌표로 탭
    public func tapAtPoint(x: Double, y: Double) async throws {
        let client = try getClient()
        try await client.tapAtPoint(x: x, y: y)
    }

    // MARK: - 텍스트 입력

    /// 텍스트 입력
    public func typeText(
        _ text: String,
        label: String? = nil,
        elementType: AXElementType? = nil,
        submit: Bool = false,
    ) async throws {
        let client = try getClient()
        let target = label.map { ElementTarget(elementType: elementType, selector: .label($0)) }

        guard let target else {
            let bundleIds = try await foregroundAppBundleIds()
            guard let firstBundleId = bundleIds.first else {
                throw TypeTextError.noForegroundApp
            }
            try await client.typeText(
                bundleId: firstBundleId,
                text: text,
                element: nil,
                submit: submit,
            )
            return
        }

        try await tryOnForegroundApps(
            client: client,
            onAllFailed: TypeTextError.elementNotFound(label: label ?? ""),
        ) { bundleId in
            try await client.typeText(
                bundleId: bundleId,
                text: text,
                element: target,
                submit: submit,
            )
        }
    }

    // MARK: - 드래그

    /// label로 드래그
    public func dragByLabel(
        sourceLabel: String,
        targetLabel: String,
        sourceElementType: AXElementType? = nil,
        targetElementType: AXElementType? = nil,
        pressDuration: Double = 0.5,
    ) async throws {
        let client = try getClient()
        let source = ElementTarget(elementType: sourceElementType, selector: .label(sourceLabel))
        let target = ElementTarget(elementType: targetElementType, selector: .label(targetLabel))

        try await tryOnForegroundApps(
            client: client,
            onAllFailed: DragError.elementNotFound(
                sourceLabel: sourceLabel,
                targetLabel: targetLabel,
            ),
        ) { bundleId in
            try await client.drag(
                bundleId: bundleId,
                source: source,
                target: target,
                pressDuration: pressDuration,
            )
        }
    }

    // MARK: - 스와이프

    /// label로 스와이프
    public func swipeByLabel(
        direction: SwipeDirection,
        label: String? = nil,
        elementType: AXElementType? = nil,
    ) async throws {
        let client = try getClient()
        let target = label.map { ElementTarget(elementType: elementType, selector: .label($0)) }

        guard let target else {
            let bundleIds = try await foregroundAppBundleIds()
            guard let firstBundleId = bundleIds.first else {
                throw SwipeError.noForegroundApp
            }
            try await client.swipe(bundleId: firstBundleId, direction: direction, element: nil)
            return
        }

        try await tryOnForegroundApps(
            client: client,
            onAllFailed: SwipeError.elementNotFound(label: label ?? ""),
        ) { bundleId in
            try await client.swipe(bundleId: bundleId, direction: direction, element: target)
        }
    }

    // MARK: - 핀치

    /// label로 핀치 줌
    public func pinchByLabel(
        scale: Double,
        velocity: Double = 100,
        label: String? = nil,
        elementType: AXElementType? = nil,
    ) async throws {
        let client = try getClient()
        let target = label.map { ElementTarget(elementType: elementType, selector: .label($0)) }

        guard let target else {
            let bundleIds = try await foregroundAppBundleIds()
            guard let firstBundleId = bundleIds.first else {
                throw PinchError.noForegroundApp
            }
            try await client.pinch(
                bundleId: firstBundleId,
                scale: scale,
                velocity: velocity,
                element: nil,
            )
            return
        }

        try await tryOnForegroundApps(
            client: client,
            onAllFailed: PinchError.elementNotFound(label: label ?? ""),
        ) { bundleId in
            try await client.pinch(
                bundleId: bundleId,
                scale: scale,
                velocity: velocity,
                element: target,
            )
        }
    }

    // MARK: - 하드웨어 버튼

    /// 하드웨어 버튼 누르기
    public func pressButton(_ button: HardwareButton) async throws {
        let client = try getClient()
        try await client.pressButton(button)
    }

    // MARK: - Private

    /// foreground 앱들을 순서대로 시도하여 첫 번째 성공하는 앱에서 작업 수행
    private func tryOnForegroundApps<T>(
        client _: UIAutomationClient,
        onAllFailed: @autoclosure () -> Error,
        _ operation: (String) async throws -> T,
    ) async throws -> T {
        let bundleIds = try await foregroundAppBundleIds()

        for bundleId in bundleIds {
            do {
                return try await operation(bundleId)
            } catch {
                continue
            }
        }
        throw onAllFailed()
    }

    // MARK: - Errors

    public enum TapError: Error {
        case elementNotFound(label: String)
    }

    public enum TypeTextError: Error {
        case noForegroundApp
        case elementNotFound(label: String)
    }

    public enum DragError: Error {
        case elementNotFound(sourceLabel: String, targetLabel: String)
    }

    public enum SwipeError: Error {
        case noForegroundApp
        case elementNotFound(label: String)
    }

    public enum PinchError: Error {
        case noForegroundApp
        case elementNotFound(label: String)
    }

    public enum DeviceSelectionError: Error, LocalizedError {
        case noDeviceSelected
        case deviceNotFound(String)

        public var errorDescription: String? {
            switch self {
            case .noDeviceSelected:
                """
                No device selected.

                Use list_devices to see available devices,
                then use select_device to choose one.
                """
            case .deviceNotFound(let udid):
                "Device not found: \(udid)"
            }
        }
    }
}
