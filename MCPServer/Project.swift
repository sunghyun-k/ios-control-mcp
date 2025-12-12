import Foundation
import ProjectDescription

/// 프로젝트 루트 경로 (Project.swift 위치 기준으로 절대 경로 계산)
let projectRoot: String = URL(filePath: #filePath)
    .deletingLastPathComponent() // MCPServer
    .deletingLastPathComponent() // 프로젝트 루트
    .path

/// 버전 파일 생성 스크립트
let generateVersionScript = TargetScript.pre(
    script: """
    VERSION=$(node -p "require('$SRCROOT/../package.json').version")
    VERSION_FILE="$SRCROOT/Sources/Generated/Version.swift"
    mkdir -p "$(dirname "$VERSION_FILE")"
    cat > "$VERSION_FILE" << EOF
    // Auto-generated file - DO NOT EDIT
    let appVersion = "$VERSION"
    EOF
    """,
    name: "Generate Version",
    inputPaths: ["$SRCROOT/../package.json"],
    outputPaths: ["$SRCROOT/Sources/Generated/Version.swift"],
)

/// 공통 환경변수
let commonArguments: Arguments = .arguments(
    environmentVariables: [
        "IOS_CONTROL_WORKSPACE_PATH": .environmentVariable(
            value: "\(projectRoot)/iOSControlMCP.xcworkspace",
            isEnabled: true,
        ),
    ],
)

let project = Project(
    name: "MCPServer",
    options: .options(
        automaticSchemesOptions: .disabled,
    ),
    packages: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.2"),
    ],
    targets: [
        .target(
            name: "iOSAutomation",
            destinations: .macOS,
            product: .staticLibrary,
            bundleId: "",
            deploymentTargets: .macOS("14.0"),
            buildableFolders: ["Sources/iOSAutomation"],
            dependencies: [
                .project(target: "Common", path: "../Common"),
            ],
        ),
        .target(
            name: "iOSAutomationTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.example.iOSAutomationTests",
            deploymentTargets: .macOS("14.0"),
            buildableFolders: ["Tests/iOSAutomationTests"],
            dependencies: [
                .target(name: "iOSAutomation"),
            ],
        ),
        .target(
            name: "MCPServer",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "",
            deploymentTargets: .macOS("14.0"),
            sources: [.generated("Sources/Generated/Version.swift")],
            buildableFolders: ["Sources/MCPServer"],
            scripts: [generateVersionScript],
            dependencies: [
                .target(name: "iOSAutomation"),
                .package(product: "MCP", type: .runtime),
            ],
        ),
    ],
    schemes: [
        .scheme(
            name: "MCPServer",
            shared: true,
            buildAction: .buildAction(targets: ["MCPServer"]),
            runAction: .runAction(
                executable: "MCPServer",
                arguments: commonArguments,
            ),
        ),
        .scheme(
            name: "iOSAutomationTests",
            shared: true,
            buildAction: .buildAction(targets: ["iOSAutomationTests"]),
            testAction: .targets(
                ["iOSAutomationTests"],
                arguments: commonArguments,
            ),
        ),
    ],
)
