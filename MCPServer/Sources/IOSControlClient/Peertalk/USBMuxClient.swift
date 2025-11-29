import Foundation

// MARK: - USBMux Errors

public enum USBMuxError: Error {
    case socketCreationFailed(Int32)
    case connectionFailed(Int32)
    case sendFailed(Int32)
    case receiveFailed(Int32)
    case invalidPacket
    case deviceNotFound
    case connectionRefused
    case timeout
    case alreadyListening
}

// MARK: - USBMux Client

/// usbmuxd 클라이언트
/// /var/run/usbmuxd 유닉스 도메인 소켓에 연결하여 iOS 기기 연결/해제 이벤트를 수신합니다.
public actor USBMuxClient {
    private static let socketPath = "/var/run/usbmuxd"

    private var fileDescriptor: Int32 = -1
    private var nextTag: UInt32 = 1
    private var isListening = false
    private var connectedDevices: [Int: USBMuxDeviceInfo] = [:]

    public init() {}

    // MARK: - Connection

    /// usbmuxd에 연결
    public func connect() throws {
        guard fileDescriptor == -1 else { return }

        // 유닉스 도메인 소켓 생성
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw USBMuxError.socketCreationFailed(errno)
        }

        // SIGPIPE 방지
        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))

        // usbmuxd에 연결
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = Self.socketPath.withCString { path in
            withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: 104) { dest in
                    strcpy(dest, path)
                }
            }
        }

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard result == 0 else {
            close(fd)
            throw USBMuxError.connectionFailed(errno)
        }

        self.fileDescriptor = fd
    }

    /// 연결 해제
    public func disconnect() {
        guard fileDescriptor >= 0 else { return }
        close(fileDescriptor)
        fileDescriptor = -1
        isListening = false
        connectedDevices.removeAll()
    }

    // MARK: - Listening

    /// 기기 연결/해제 이벤트 수신 시작
    public func startListening() async throws -> AsyncStream<USBMuxDeviceEvent> {
        guard !isListening else {
            throw USBMuxError.alreadyListening
        }

        try connect()
        isListening = true

        // Listen 요청 전송
        let tag = getNextTag()
        let packet = try USBMuxPacket.listenRequest(tag: tag)
        try sendPacket(packet)

        // Listen 응답 수신
        let response = try readPacket()
        if let plist = response.payloadAsPlist(),
           let number = plist["Number"] as? Int,
           number != 0 {
            throw USBMuxError.connectionRefused
        }

        // 이벤트 스트림 생성
        return AsyncStream { continuation in
            Task {
                do {
                    while self.isListening {
                        let packet = try await self.readPacketAsync()
                        if let event = self.parseDeviceEvent(packet: packet) {
                            continuation.yield(event)
                        }
                    }
                } catch {
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.stopListening()
                }
            }
        }
    }

    /// 이벤트 수신 중지
    public func stopListening() {
        isListening = false
    }

    // MARK: - Device Connection

    /// 특정 기기의 포트에 연결
    /// - Parameters:
    ///   - deviceID: usbmuxd 내부 기기 ID
    ///   - port: 연결할 포트 번호
    /// - Returns: 연결된 파일 디스크립터
    public nonisolated func connectToDevice(deviceID: Int, port: UInt16) throws -> Int32 {
        // 새 연결용으로 직접 소켓 생성
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw USBMuxError.socketCreationFailed(errno)
        }

        // SIGPIPE 방지
        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))

        // usbmuxd에 연결
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = Self.socketPath.withCString { path in
            withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: 104) { dest in
                    strcpy(dest, path)
                }
            }
        }

        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard connectResult == 0 else {
            close(fd)
            throw USBMuxError.connectionFailed(errno)
        }

        // Connect 요청 전송
        let tag = UInt32.random(in: 1...UInt32.max)
        let packet = try USBMuxPacket.connectRequest(tag: tag, deviceID: deviceID, port: port)
        let data = packet.toData()
        let sendResult = data.withUnsafeBytes { bytes in
            send(fd, bytes.baseAddress, data.count, 0)
        }

        guard sendResult == data.count else {
            close(fd)
            throw USBMuxError.sendFailed(errno)
        }

        // 응답 수신
        var headerData = Data(count: USBMuxPacketHeader.headerSize)
        let headerResult = headerData.withUnsafeMutableBytes { bytes in
            recv(fd, bytes.baseAddress, USBMuxPacketHeader.headerSize, 0)
        }

        guard headerResult == USBMuxPacketHeader.headerSize,
              let header = USBMuxPacketHeader.from(data: headerData) else {
            close(fd)
            throw USBMuxError.receiveFailed(errno)
        }

        let payloadSize = Int(header.size) - USBMuxPacketHeader.headerSize
        if payloadSize > 0 {
            var payload = Data(count: payloadSize)
            let payloadResult = payload.withUnsafeMutableBytes { bytes in
                recv(fd, bytes.baseAddress, payloadSize, 0)
            }

            guard payloadResult == payloadSize else {
                close(fd)
                throw USBMuxError.receiveFailed(errno)
            }

            // 응답 확인
            if let plist = try? PropertyListSerialization.propertyList(from: payload, options: [], format: nil) as? [String: Any],
               let number = plist["Number"] as? Int,
               number != 0 {
                close(fd)
                throw USBMuxError.connectionRefused
            }
        }

        // 연결된 소켓 반환
        return fd
    }

    /// 현재 연결된 기기 목록
    public func getConnectedDevices() -> [USBMuxDeviceInfo] {
        Array(connectedDevices.values)
    }

    /// UDID로 기기 찾기
    public func findDevice(udid: String) -> USBMuxDeviceInfo? {
        connectedDevices.values.first { $0.serialNumber == udid }
    }

    // MARK: - Packet I/O

    private func getNextTag() -> UInt32 {
        let tag = nextTag
        nextTag += 1
        return tag
    }

    private func sendPacket(_ packet: USBMuxPacket) throws {
        let data = packet.toData()
        let result = data.withUnsafeBytes { bytes in
            send(fileDescriptor, bytes.baseAddress, data.count, 0)
        }

        guard result == data.count else {
            throw USBMuxError.sendFailed(errno)
        }
    }

    private func readPacket() throws -> USBMuxPacket {
        // 헤더 읽기
        var headerData = Data(count: USBMuxPacketHeader.headerSize)
        let headerResult = headerData.withUnsafeMutableBytes { bytes in
            recv(fileDescriptor, bytes.baseAddress, USBMuxPacketHeader.headerSize, 0)
        }

        guard headerResult == USBMuxPacketHeader.headerSize else {
            throw USBMuxError.receiveFailed(errno)
        }

        guard let header = USBMuxPacketHeader.from(data: headerData) else {
            throw USBMuxError.invalidPacket
        }

        // 페이로드 읽기
        let payloadSize = Int(header.size) - USBMuxPacketHeader.headerSize
        var payload = Data()

        if payloadSize > 0 {
            payload = Data(count: payloadSize)
            let payloadResult = payload.withUnsafeMutableBytes { bytes in
                recv(fileDescriptor, bytes.baseAddress, payloadSize, 0)
            }

            guard payloadResult == payloadSize else {
                throw USBMuxError.receiveFailed(errno)
            }
        }

        return USBMuxPacket(header: header, payload: payload)
    }

    private func readPacketAsync() async throws -> USBMuxPacket {
        // Actor-isolated 읽기를 백그라운드에서 수행
        let fd = self.fileDescriptor
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let packet = try Self.readPacketFromFD(fd)
                    continuation.resume(returning: packet)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 파일 디스크립터에서 패킷 읽기 (static으로 actor isolation 회피)
    private nonisolated static func readPacketFromFD(_ fd: Int32) throws -> USBMuxPacket {
        // 헤더 읽기
        var headerData = Data(count: USBMuxPacketHeader.headerSize)
        let headerResult = headerData.withUnsafeMutableBytes { bytes in
            recv(fd, bytes.baseAddress, USBMuxPacketHeader.headerSize, 0)
        }

        guard headerResult == USBMuxPacketHeader.headerSize else {
            throw USBMuxError.receiveFailed(errno)
        }

        guard let header = USBMuxPacketHeader.from(data: headerData) else {
            throw USBMuxError.invalidPacket
        }

        // 페이로드 읽기
        let payloadSize = Int(header.size) - USBMuxPacketHeader.headerSize
        var payload = Data()

        if payloadSize > 0 {
            payload = Data(count: payloadSize)
            let payloadResult = payload.withUnsafeMutableBytes { bytes in
                recv(fd, bytes.baseAddress, payloadSize, 0)
            }

            guard payloadResult == payloadSize else {
                throw USBMuxError.receiveFailed(errno)
            }
        }

        return USBMuxPacket(header: header, payload: payload)
    }

    // MARK: - Event Parsing

    private func parseDeviceEvent(packet: USBMuxPacket) -> USBMuxDeviceEvent? {
        guard let plist = packet.payloadAsPlist(),
              let messageType = plist["MessageType"] as? String else {
            return nil
        }

        switch messageType {
        case "Attached":
            if let deviceInfo = USBMuxDeviceInfo.from(plist: plist) {
                connectedDevices[deviceInfo.deviceID] = deviceInfo
                return .attached(deviceInfo)
            }

        case "Detached":
            if let deviceID = plist["DeviceID"] as? Int,
               let deviceInfo = connectedDevices.removeValue(forKey: deviceID) {
                return .detached(deviceInfo)
            }

        default:
            break
        }

        return nil
    }
}

// MARK: - Device Event

public enum USBMuxDeviceEvent: Sendable {
    case attached(USBMuxDeviceInfo)
    case detached(USBMuxDeviceInfo)
}
