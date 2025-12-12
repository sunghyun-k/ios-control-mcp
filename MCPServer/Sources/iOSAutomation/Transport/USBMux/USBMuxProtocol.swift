import Foundation

// MARK: - USBMux Packet Types

/// USBMux 패킷 타입 (usbmuxd 프로토콜)
public enum USBMuxPacketType: UInt32 {
    case result = 1
    case connect = 2
    case listen = 3
    case deviceAdd = 4
    case deviceRemove = 5
    case plistPayload = 8
}

/// USBMux 패킷 프로토콜
public enum USBMuxPacketProtocol: UInt32 {
    case binary = 0
    case plist = 1
}

/// USBMux 응답 코드
public enum USBMuxReplyCode: Int {
    case ok = 0
    case badCommand = 1
    case badDevice = 2
    case connectionRefused = 3
    case badVersion = 6
}

// MARK: - USBMux Packet Header

/// USBMux 패킷 헤더 (16 bytes)
public struct USBMuxPacketHeader {
    public let size: UInt32
    public let `protocol`: UInt32
    public let type: UInt32
    public let tag: UInt32

    public static let headerSize = 16

    public init(size: UInt32, protocol: UInt32, type: UInt32, tag: UInt32) {
        self.size = size
        self.protocol = `protocol`
        self.type = type
        self.tag = tag
    }

    /// Data로 변환
    public func toData() -> Data {
        var data = Data(capacity: Self.headerSize)
        var size = size.littleEndian
        var proto = self.protocol.littleEndian
        var type = type.littleEndian
        var tag = tag.littleEndian

        withUnsafeBytes(of: &size) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &proto) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &type) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &tag) { data.append(contentsOf: $0) }

        return data
    }

    /// Data에서 파싱
    public static func from(data: Data) -> USBMuxPacketHeader? {
        guard data.count >= headerSize else { return nil }

        return data.withUnsafeBytes { bytes in
            let size = bytes.load(fromByteOffset: 0, as: UInt32.self).littleEndian
            let proto = bytes.load(fromByteOffset: 4, as: UInt32.self).littleEndian
            let type = bytes.load(fromByteOffset: 8, as: UInt32.self).littleEndian
            let tag = bytes.load(fromByteOffset: 12, as: UInt32.self).littleEndian

            return USBMuxPacketHeader(size: size, protocol: proto, type: type, tag: tag)
        }
    }
}

// MARK: - USBMux Packet

/// USBMux 패킷
public struct USBMuxPacket {
    public let header: USBMuxPacketHeader
    public let payload: Data

    public init(type: USBMuxPacketType, tag: UInt32, payload: Data) {
        let size = UInt32(USBMuxPacketHeader.headerSize + payload.count)
        header = USBMuxPacketHeader(
            size: size,
            protocol: USBMuxPacketProtocol.plist.rawValue,
            type: type.rawValue,
            tag: tag,
        )
        self.payload = payload
    }

    public init(header: USBMuxPacketHeader, payload: Data) {
        self.header = header
        self.payload = payload
    }

    /// Encodable 페이로드로 패킷 생성
    public static func plistPacket(
        type: USBMuxPacketType,
        tag: UInt32,
        content: some Encodable,
    ) throws -> USBMuxPacket {
        let payload = try PropertyListEncoder().encode(content)
        return USBMuxPacket(type: type, tag: tag, payload: payload)
    }

    /// 전체 데이터로 변환
    public func toData() -> Data {
        var data = header.toData()
        data.append(payload)
        return data
    }

    /// 페이로드를 Decodable 타입으로 파싱
    public func decodePayload<T: Decodable>(_ type: T.Type) -> T? {
        guard !payload.isEmpty else { return nil }
        return try? PropertyListDecoder().decode(type, from: payload)
    }
}

// MARK: - USBMux Device Info

/// USB로 연결된 기기 정보
public struct USBMuxDeviceInfo: Sendable {
    /// usbmuxd 내부 기기 ID
    public let deviceID: Int
    /// 기기 UDID
    public let serialNumber: String
    /// 연결 타입 (USB, WiFi)
    public let connectionType: String
    /// 제품 ID
    public let productID: Int?
    /// 위치 ID
    public let locationID: Int?

    public init(
        deviceID: Int,
        serialNumber: String,
        connectionType: String,
        productID: Int? = nil,
        locationID: Int? = nil,
    ) {
        self.deviceID = deviceID
        self.serialNumber = serialNumber
        self.connectionType = connectionType
        self.productID = productID
        self.locationID = locationID
    }

    /// Plist 데이터에서 파싱
    public static func from(plistData: Data) -> USBMuxDeviceInfo? {
        guard let plist = try? PropertyListDecoder().decode(USBMuxDevicePlist.self, from: plistData)
        else {
            return nil
        }

        return USBMuxDeviceInfo(
            deviceID: plist.properties.deviceID,
            serialNumber: plist.properties.serialNumber,
            connectionType: plist.properties.connectionType ?? "USB",
            productID: plist.properties.productID,
            locationID: plist.properties.locationID,
        )
    }
}

/// USBMux 디바이스 Plist 응답 구조
private struct USBMuxDevicePlist: Decodable {
    let properties: Properties

    struct Properties: Decodable {
        let deviceID: Int
        let serialNumber: String
        let connectionType: String?
        let productID: Int?
        let locationID: Int?

        enum CodingKeys: String, CodingKey {
            case deviceID = "DeviceID"
            case serialNumber = "SerialNumber"
            case connectionType = "ConnectionType"
            case productID = "ProductID"
            case locationID = "LocationID"
        }
    }

    enum CodingKeys: String, CodingKey {
        case properties = "Properties"
    }
}

// MARK: - USBMux Message Types

public enum USBMuxMessageType: String, Codable {
    case listen = "Listen"
    case connect = "Connect"
    case attached = "Attached"
    case detached = "Detached"
    case result = "Result"
}

// MARK: - USBMux Request/Response Models

/// USBMux 요청 기본 구조
private struct USBMuxRequest: Encodable {
    let messageType: USBMuxMessageType
    let clientVersionString: String
    let progName: String

    enum CodingKeys: String, CodingKey {
        case messageType = "MessageType"
        case clientVersionString = "ClientVersionString"
        case progName = "ProgName"
    }

    init(messageType: USBMuxMessageType) {
        self.messageType = messageType
        clientVersionString = "ios-control-mcp"
        progName = "ios-control-mcp"
    }
}

/// USBMux Connect 요청
private struct USBMuxConnectRequest: Encodable {
    let messageType: USBMuxMessageType
    let clientVersionString: String
    let progName: String
    let deviceID: Int
    let portNumber: Int

    enum CodingKeys: String, CodingKey {
        case messageType = "MessageType"
        case clientVersionString = "ClientVersionString"
        case progName = "ProgName"
        case deviceID = "DeviceID"
        case portNumber = "PortNumber"
    }

    init(deviceID: Int, port: UInt16) {
        messageType = .connect
        clientVersionString = "ios-control-mcp"
        progName = "ios-control-mcp"
        self.deviceID = deviceID
        // 포트 바이트 스왑 (네트워크 바이트 오더)
        portNumber = Int(port.bigEndian)
    }
}

/// USBMux 응답 (Result)
public struct USBMuxResponse: Decodable {
    public let messageType: String?
    public let number: Int?

    enum CodingKeys: String, CodingKey {
        case messageType = "MessageType"
        case number = "Number"
    }
}

/// USBMux 이벤트 메시지 (Attached/Detached)
public struct USBMuxEventMessage: Decodable {
    public let messageType: String

    enum CodingKeys: String, CodingKey {
        case messageType = "MessageType"
    }
}

// MARK: - Helper Extensions

extension USBMuxPacket {
    /// Listen 요청 패킷 생성
    public static func listenRequest(tag: UInt32) throws -> USBMuxPacket {
        let request = USBMuxRequest(messageType: .listen)
        return try plistPacket(type: .plistPayload, tag: tag, content: request)
    }

    /// Connect 요청 패킷 생성
    public static func connectRequest(
        tag: UInt32,
        deviceID: Int,
        port: UInt16,
    ) throws -> USBMuxPacket {
        let request = USBMuxConnectRequest(deviceID: deviceID, port: port)
        return try plistPacket(type: .plistPayload, tag: tag, content: request)
    }
}
