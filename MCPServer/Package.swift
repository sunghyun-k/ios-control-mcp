// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCPServer",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.2"),
        .package(path: "../Common"),
    ],
    targets: [
        // HTTP 클라이언트 라이브러리
        .target(
            name: "IOSControlClient",
            dependencies: ["Common"]
        ),
        // MCP 서버 실행 타겟
        .executableTarget(
            name: "MCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                "IOSControlClient",
            ]
        ),
        // 테스트용 CLI
        .executableTarget(
            name: "Playground",
            dependencies: ["IOSControlClient"]
        ),
    ]
)
