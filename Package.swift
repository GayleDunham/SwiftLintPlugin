// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftLintPlugin",

    products: [
        .plugin(
            name: "SwiftLintBuildTool",
            targets: ["SwiftLintBuildTool"]),
        .plugin(
            name: "SwiftLintLinter",
            targets: ["SwiftLintLinter"]),
        .plugin(
            name: "SwiftLintFix",
            targets: ["SwiftLintFix"]),
        .plugin(
            name: "SwiftLintRules",
            targets: ["SwiftLintRules"]),
        .plugin(
            name: "SwiftLintVersion",
            targets: ["SwiftLintVersion"]),
    ],

    targets: [
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.57.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "a1bbafe57538077f3abe4cfb004b0464dcd87e8c23611a2153c675574b858b3a"
        ),
        .target(
            name: "DDSSwiftLint",
            dependencies: [],
            path: "Plugins",
            sources: ["DDSSwiftLint.swift", "../swiftlint.yml"],
            plugins: [ .plugin(name: "SwiftLintBuildTool") ]
        ),
        .plugin(
            name: "SwiftLintBuildTool",
            capability: .buildTool(),
            dependencies: ["SwiftLintBinary"]
        ),
        .plugin(
            name: "SwiftLintLinter",
            capability: .command(
                intent: .custom(
                    verb: "swiftlint-lint",
                    description: "Print lint warnings and errors.")
            ),
            dependencies: ["SwiftLintBinary"]
        ),
        .plugin(
            name: "SwiftLintFix",
            capability: .command(
                intent: .custom(
                    verb: "swiftlint-fix",
                    description: "Correct linter violations if possible."),
                permissions: [.writeToPackageDirectory(reason: "This command attempts to fix lint issues")]
            ),
            dependencies: ["SwiftLintBinary"]
        ),
        .plugin(
            name: "SwiftLintRules",
            capability: .command(
                intent: .custom(
                    verb: "swiftlint-rules",
                    description: "Display the list of SwiftLint rules and their identifiers.")
            ),
            dependencies: ["SwiftLintBinary"]
        ),
        .plugin(
            name: "SwiftLintVersion",
            capability: .command(
                intent: .custom(
                    verb: "swiftlint-version",
                    description: "Display the current version of SwiftLint.")
            ),
            dependencies: ["SwiftLintBinary"]
        ),
    ]
)
