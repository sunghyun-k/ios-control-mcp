import ProjectDescription

let project = Project(
    name: "UIAutomationServer",
    options: .options(
        automaticSchemesOptions: .disabled,
    ),
    packages: [
        .package(url: "https://github.com/swhitty/FlyingFox", from: "0.26.0"),
    ],
    targets: [
        .target(
            name: "HostApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.ioscontrol.hostapp",
            deploymentTargets: .iOS("16.0"),
            buildableFolders: [
                "Sources/HostApp",
            ],
        ),
        .target(
            name: "UIAutomationServer",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.ioscontrol.uiautomationserver",
            deploymentTargets: .iOS("16.0"),
            buildableFolders: [
                "Sources/UIAutomationServer",
            ],
            dependencies: [
                .target(name: "HostApp"),
                .package(product: "FlyingFox", type: .runtime),
                .project(target: "Common", path: "../Common"),
            ],
        ),
    ],
    schemes: [
        .scheme(
            name: "UIAutomationServer",
            shared: true,
            buildAction: .buildAction(targets: ["UIAutomationServer"]),
            testAction: .targets(["UIAutomationServer"]),
        ),
    ],
)
