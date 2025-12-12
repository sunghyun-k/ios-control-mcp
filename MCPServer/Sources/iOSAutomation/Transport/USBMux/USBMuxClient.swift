import Foundation

// MARK: - USBMux Errors

public enum USBMuxError: Error, LocalizedError {
    case socketCreationFailed(Int32)
    case connectionFailed(Int32)
    case sendFailed(Int32)
    case receiveFailed(Int32)
    case invalidPacket
    case connectionRefused
    case deviceNotFound(udid: String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .socketCreationFailed(let errno):
            "Failed to create socket: \(errno)"
        case .connectionFailed(let errno):
            "Failed to connect to usbmuxd: \(errno)"
        case .sendFailed(let errno):
            "Failed to send packet: \(errno)"
        case .receiveFailed(let errno):
            "Failed to receive packet: \(errno)"
        case .invalidPacket:
            "Invalid packet received"
        case .connectionRefused:
            "Connection refused by device"
        case .deviceNotFound(let udid):
            "Device not found: \(udid)"
        case .timeout:
            "Operation timed out"
        }
    }
}

// MARK: - USBMux Client

/// usbmuxd 클라이언트
/// /var/run/usbmuxd 유닉스 도메인 소켓에 연결하여 iOS 기기와 통신합니다.
public final class USBMuxClient: @unchecked Sendable {
    private static let socketPath = "/var/run/usbmuxd"

    public init() {}

    // MARK: - Device Discovery

    /// 연결된 기기 목록 조회 (Listen 요청 후 일정 시간 대기)
    public func listConnectedDevices(timeout: TimeInterval = 0.5) throws -> [USBMuxDeviceInfo] {
        let fd = try connectToUsbmuxd()
        defer { close(fd) }

        // Listen 요청 전송
        let tag = UInt32.random(in: 1 ... UInt32.max)
        let packet = try USBMuxPacket.listenRequest(tag: tag)
        try sendPacket(fd: fd, packet: packet)

        // Listen 응답 수신
        let response = try readPacket(fd: fd)
        if let result = response.decodePayload(USBMuxResponse.self),
           let number = result.number,
           number != 0
        {
            throw USBMuxError.connectionRefused
        }

        // 기기 연결 이벤트 수신 (타임아웃까지)
        var devices: [Int: USBMuxDeviceInfo] = [:]
        let startTime = Date()

        // 소켓을 non-blocking으로 설정
        var flags = fcntl(fd, F_GETFL, 0)
        flags |= O_NONBLOCK
        fcntl(fd, F_SETFL, flags)

        while Date().timeIntervalSince(startTime) < timeout {
            if let packet = try? readPacket(fd: fd),
               let event = packet.decodePayload(USBMuxEventMessage.self)
            {
                if event.messageType == USBMuxMessageType.attached.rawValue,
                   let deviceInfo = USBMuxDeviceInfo.from(plistData: packet.payload)
                {
                    devices[deviceInfo.deviceID] = deviceInfo
                }
            } else {
                // 데이터 없으면 잠시 대기
                Thread.sleep(forTimeInterval: 0.05)
            }
        }

        return Array(devices.values)
    }

    /// UDID로 DeviceID 조회
    public func findDeviceID(udid: String, timeout: TimeInterval = 0.5) throws -> Int {
        let devices = try listConnectedDevices(timeout: timeout)
        guard let device = devices.first(where: { $0.serialNumber == udid }) else {
            throw USBMuxError.deviceNotFound(udid: udid)
        }
        return device.deviceID
    }

    // MARK: - Device Connection

    /// 특정 기기의 포트에 연결
    /// - Parameters:
    ///   - deviceID: usbmuxd 내부 기기 ID
    ///   - port: 연결할 포트 번호
    /// - Returns: 연결된 파일 디스크립터
    public func connectToDevice(deviceID: Int, port: UInt16) throws -> Int32 {
        let fd = try connectToUsbmuxd()

        // Connect 요청 전송
        let tag = UInt32.random(in: 1 ... UInt32.max)
        let packet = try USBMuxPacket.connectRequest(tag: tag, deviceID: deviceID, port: port)
        try sendPacket(fd: fd, packet: packet)

        // 응답 수신
        let response = try readPacket(fd: fd)
        if let result = response.decodePayload(USBMuxResponse.self),
           let number = result.number,
           number != 0
        {
            close(fd)
            throw USBMuxError.connectionRefused
        }

        // 연결된 소켓 반환 (이제 기기와 직접 통신 가능)
        return fd
    }

    /// UDID로 기기의 포트에 연결
    public func connectToDevice(udid: String, port: UInt16) throws -> Int32 {
        let deviceID = try findDeviceID(udid: udid)
        return try connectToDevice(deviceID: deviceID, port: port)
    }

    // MARK: - Private

    /// usbmuxd에 연결
    private func connectToUsbmuxd() throws -> Int32 {
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

        return fd
    }

    /// 패킷 전송
    private func sendPacket(fd: Int32, packet: USBMuxPacket) throws {
        let data = packet.toData()
        let result = data.withUnsafeBytes { bytes in
            send(fd, bytes.baseAddress, data.count, 0)
        }

        guard result == data.count else {
            throw USBMuxError.sendFailed(errno)
        }
    }

    /// 패킷 수신
    private func readPacket(fd: Int32) throws -> USBMuxPacket {
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
}
