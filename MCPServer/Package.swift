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
        .executableTarget(
            name: "MCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                "Common",
            ]
        ),
    ]
)
