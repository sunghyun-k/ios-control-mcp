import ProjectDescription

let project = Project(
    name: "Common",
    options: .options(
        automaticSchemesOptions: .disabled,
    ),
    targets: [
        .target(
            name: "Common",
            destinations: Set(Destination.allCases),
            product: .staticFramework,
            bundleId: "",
            deploymentTargets: .multiplatform(iOS: "14.0", macOS: "11.0"),
            buildableFolders: [
                "Sources",
            ],
        ),
    ],
)
