// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "Common", targets: ["Common"]),
    ],
    targets: [
        .target(name: "Common"),
    ]
)
