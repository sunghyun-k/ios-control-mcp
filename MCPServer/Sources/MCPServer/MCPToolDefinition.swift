import Foundation
import iOSAutomation
import MCP

/// MCP 도구 정의 프로토콜
/// 이 프로토콜을 준수하면 ToolRegistry에 자동 등록됨
protocol MCPToolDefinition {
    /// 도구 이름 (snake_case)
    static var name: String { get }

    /// 도구 설명 (LLM이 이해할 수 있도록 영어로 작성)
    static var description: String { get }

    /// 입력 파라미터 정의
    static var parameters: [ToolParameter] { get }

    /// 도구 실행
    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content]
}

/// 도구 파라미터 정의
struct ToolParameter {
    let name: String
    let type: ParameterType
    let description: String
    let required: Bool
    let enumValues: [String]?

    init(
        name: String,
        type: ParameterType,
        description: String,
        required: Bool = true,
        enumValues: [String]? = nil,
    ) {
        self.name = name
        self.type = type
        self.description = description
        self.required = required
        self.enumValues = enumValues
    }

    enum ParameterType: String {
        case string
        case number
        case boolean
        case integer
    }
}

// MARK: - 프로토콜 확장: Tool 객체 자동 생성

extension MCPToolDefinition {
    /// MCP Tool 객체 자동 생성
    static var tool: Tool {
        var properties: [String: Value] = [:]
        var requiredParams: [Value] = []

        for param in parameters {
            var propDef: [String: Value] = [
                "type": .string(param.type.rawValue),
                "description": .string(param.description),
            ]

            if let enumValues = param.enumValues {
                propDef["enum"] = .array(enumValues.map { .string($0) })
            }

            properties[param.name] = .object(propDef)

            if param.required {
                requiredParams.append(.string(param.name))
            }
        }

        var schema: [String: Value] = [
            "type": .string("object"),
            "properties": .object(properties),
        ]

        if !requiredParams.isEmpty {
            schema["required"] = .array(requiredParams)
        }

        return Tool(
            name: name,
            description: description,
            inputSchema: .object(schema),
        )
    }
}

// MARK: - 파라미터 추출 헬퍼

extension [String: MCP.Value] {
    func string(_ key: String) throws -> String {
        guard let value = self[key]?.stringValue else {
            throw ToolError.missingArgument(key)
        }
        return value
    }

    func optionalString(_ key: String) -> String? {
        self[key]?.stringValue
    }

    func double(_ key: String) throws -> Double {
        guard let value = self[key]?.doubleValue else {
            throw ToolError.missingArgument(key)
        }
        return value
    }

    func optionalDouble(_ key: String) -> Double? {
        self[key]?.doubleValue
    }

    func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        self[key]?.boolValue ?? defaultValue
    }
}
