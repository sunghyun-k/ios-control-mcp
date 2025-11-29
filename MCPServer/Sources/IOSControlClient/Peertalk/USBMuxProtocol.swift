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
        var size = self.size.littleEndian
        var proto = self.protocol.littleEndian
        var type = self.type.littleEndian
        var tag = self.tag.littleEndian

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
        self.header = USBMuxPacketHeader(
            size: size,
            protocol: USBMuxPacketProtocol.plist.rawValue,
            type: type.rawValue,
            tag: tag
        )
        self.payload = payload
    }

    public init(header: USBMuxPacketHeader, payload: Data) {
        self.header = header
        self.payload = payload
    }

    /// Plist 페이로드로 패킷 생성
    public static func plistPacket(type: USBMuxPacketType, tag: UInt32, plist: [String: Any]) throws -> USBMuxPacket {
        let payload = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        return USBMuxPacket(type: type, tag: tag, payload: payload)
    }

    /// 전체 데이터로 변환
    public func toData() -> Data {
        var data = header.toData()
        data.append(payload)
        return data
    }

    /// 페이로드를 Plist 딕셔너리로 파싱
    public func payloadAsPlist() -> [String: Any]? {
        guard !payload.isEmpty else { return nil }
        return try? PropertyListSerialization.propertyList(
            from: payload,
            options: [],
            format: nil
        ) as? [String: Any]
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

    public init(deviceID: Int, serialNumber: String, connectionType: String, productID: Int? = nil, locationID: Int? = nil) {
        self.deviceID = deviceID
        self.serialNumber = serialNumber
        self.connectionType = connectionType
        self.productID = productID
        self.locationID = locationID
    }

    /// Plist 딕셔너리에서 파싱
    public static func from(plist: [String: Any]) -> USBMuxDeviceInfo? {
        guard let properties = plist["Properties"] as? [String: Any],
              let deviceID = properties["DeviceID"] as? Int,
              let serialNumber = properties["SerialNumber"] as? String else {
            return nil
        }

        return USBMuxDeviceInfo(
            deviceID: deviceID,
            serialNumber: serialNumber,
            connectionType: properties["ConnectionType"] as? String ?? "USB",
            productID: properties["ProductID"] as? Int,
            locationID: properties["LocationID"] as? Int
        )
    }
}

// MARK: - USBMux Message Types

public enum USBMuxMessageType: String {
    case listen = "Listen"
    case connect = "Connect"
    case attached = "Attached"
    case detached = "Detached"
    case result = "Result"
}

// MARK: - Helper Extensions

extension USBMuxPacket {
    /// Listen 요청 패킷 생성
    /// 패킷 타입은 항상 plistPayload(8)이고, MessageType으로 동작 구분
    public static func listenRequest(tag: UInt32) throws -> USBMuxPacket {
        let plist: [String: Any] = [
            "MessageType": USBMuxMessageType.listen.rawValue,
            "ClientVersionString": "ios-control-mcp",
            "ProgName": "ios-control-mcp"
        ]
        return try plistPacket(type: .plistPayload, tag: tag, plist: plist)
    }

    /// Connect 요청 패킷 생성
    /// 패킷 타입은 항상 plistPayload(8)이고, MessageType으로 동작 구분
    public static func connectRequest(tag: UInt32, deviceID: Int, port: UInt16) throws -> USBMuxPacket {
        // 포트 바이트 스왑 (네트워크 바이트 오더)
        let swappedPort = port.bigEndian

        let plist: [String: Any] = [
            "MessageType": USBMuxMessageType.connect.rawValue,
            "ClientVersionString": "ios-control-mcp",
            "ProgName": "ios-control-mcp",
            "DeviceID": deviceID,
            "PortNumber": Int(swappedPort)
        ]
        return try plistPacket(type: .plistPayload, tag: tag, plist: plist)
    }
}
