# SwiftLintPlugin

A Swift Package Manager plugin for SwiftLint, supporting both Swift Packages and Xcode Projects.

This package provides plugin commands and a build tool command. The build tool runs SwiftLint before each build, and any issues are displayed in the Xcode Issue Navigator and code editor. For Swift Packages, the plugin commands can be executed from either the command line or within Xcode.

These plugins respect the `exclude:` section in the top-level SwiftLint configuration file.

## Requirements

- **Recommended**: Xcode 16 or later, but you can use Xcode 14 or 15 by specifying branch `swift-5.7`

- **Recommended**: Swift 6.0 or later, but you can use Swift 5.7 or later by specifying branch `swift-5.7`

- **Required**: You must have a SwiftLint configuration file (`swiftlint.yml` or `.swiftlint.yml`) in the root folder of your package or project.

## Installation

This package contains a `binaryTarget` for the current released version 0.63.2 of SwiftLint from [realm/SwiftLint](https://github.com/realm/SwiftLint/), used by all the plugin commands and the build tool command. No installation of SwiftLint or configuring of PATH is required.

For more information on SwiftLint rules, see the [Rule Directory Reference](https://realm.github.io/SwiftLint/rule-directory.html).

## Adding Linting to a Swift Package

1. Add `SwiftLintPlugin` as a dependency of your package.

```swift
    dependencies: [
        .package(url: "https://github.com/GayleDunham/SwiftLintPlugin.git", branch: "main"),
    ],
```

2. Optionally, add the `SwiftLintBuildTool` plugin to your main target. All files in the package will be evaluated by the linter.

```swift
    targets: [
        .target(
            name: "YOUR_TARGET",
            dependencies: [],
            plugins: [ .plugin(name: "SwiftLintBuildTool", package: "SwiftLintPlugin") ]
        ),
```

## Adding Linting to an Xcode Project

### TL;DR

1. Add the package `https://github.com/GayleDunham/SwiftLintPlugin` to the project.
2. Optionally, add the `SwiftLintBuildTool` plugin to the targets you want to be evaluated by the linter.

### Add the Package to Your Project

1. In the Project Navigator, select the first item (the project).
2. In the Project Settings editor, select the project.
3. Select the Package Dependencies tab.
4. Click the + under the "Add package here" text.

![Edit the Project Package Settings](https://github.com/GayleDunham/SwiftLintPlugin/assets/4434375/59d09a38-8cce-45fc-a833-b0e6c81bf3d6)

5. Paste `https://github.com/GayleDunham/SwiftLintPlugin` in the search box.
6. Click Add Package.

![Paste the link and Add Package](https://github.com/GayleDunham/SwiftLintPlugin/assets/4434375/ee794f81-62d9-4088-a289-0e8814816ee7)

### Optionally: Add the Build Tool to Your Target

7. Select the target.
8. Select the Build Phases tab.
9. Expand Run Build Tool Plug-in and click the +.

![Edit the Target Build Settings](https://github.com/GayleDunham/SwiftLintPlugin/assets/4434375/5a415120-be99-49f1-b988-c6a39fa1de93)

10. Select SwiftLintBuildTool and click Add.

![Select the Build Tool and Add](https://github.com/GayleDunham/SwiftLintPlugin/assets/4434375/1f918208-fbe3-4821-9fbf-864ab5c44d53)

## Features

### Build Tool

The `SwiftLintBuildTool` is a pre-build command that runs SwiftLint against a target's sources directory. All lint issues are displayed in the Xcode Issue Navigator and code editor.

### Commands

Commands are run against one or more selected targets. Output appears in the Report Navigator, labeled with the command name (e.g., "SwiftLintFix").

- `SwiftLintFix`:       Modifies your files to correct lint violations if possible
- `SwiftLintLinter`:    Prints lint warnings and errors
- `SwiftLintRules`:     Displays the list of rules and their identifiers
- `SwiftLintVersion`:   Displays the current version of SwiftLint

## Running Plugin Commands from Xcode

* **From the Project Navigator:** Right-click on the first item (the project or package) in the Project Navigator, then click the command to run.

![Run Command from Project Navigator](https://github.com/GayleDunham/SwiftLintPlugin/assets/4434375/32e94147-4729-4245-b273-e8d3460f250c)

* **From the Menu:** Select the first item (the project or package) in the Project Navigator. Then in the menu bar, select File > Packages and the command to run.

![Run Command from Menu](https://github.com/GayleDunham/SwiftLintPlugin/assets/4434375/2c9b173b-b889-470d-a64c-6711fa41cbf5)

## Command Line Usage for Swift Packages

In the top-level directory of the Swift Package, execute any of the following commands.

```sh
swift package swiftlint-fix
swift package swiftlint-lint
swift package swiftlint-rules
swift package swiftlint-version
```

## xcodebuild Usage and CI Systems

```sh
xcodebuild  \
    -scheme "YOUR_PROJECT" \
    -destination "platform=macOS" \
    -skipPackagePluginValidation \
    clean build
```

> [!NOTE]
> For CI systems, specify `-skipPackagePluginValidation` to skip the validation prompt that occurs in Xcode.

## References

### SwiftLint

* SwiftLint Rule Directory Reference - [https://realm.github.io/SwiftLint/rule-directory.html](https://realm.github.io/SwiftLint/rule-directory.html)

### Example SwiftLint Configuration Files from Industry Leaders

* The Official raywenderlich.com SwiftLint Policy - [https://github.com/kodecocodes/swift-style-guide/blob/main/SWIFTLINT.markdown ](https://github.com/kodecocodes/swift-style-guide/blob/main/SWIFTLINT.markdown)
     
* com.raywenderlich.swiftlint.yml - The Official Kodeco Configuration file - [https://github.com/kodecocodes/swift-style-guide/blob/main/com.raywenderlich.swiftlint.yml ](https://github.com/kodecocodes/swift-style-guide/blob/main/com.raywenderlich.swiftlint.yml)

* The Official Kodeco Swift Style Guide - [https://github.com/kodecocodes/swift-style-guide ](https://github.com/kodecocodes/swift-style-guide)

* SwiftLee Blog: SwiftLint valuable opt-in rules to improve your code - [https://www.avanderlee.com/optimization/swiftlint-optin-rules/ ](https://www.avanderlee.com/optimization/swiftlint-optin-rules/)

* Swift API Design Guidelines - [https://www.swift.org/documentation/api-design-guidelines/ ](https://www.swift.org/documentation/api-design-guidelines/)

* Google Swift Style Guide - [https://google.github.io/swift/ ](https://google.github.io/swift/)

* LinkedIn Swift Style Guide - [https://github.com/linkedin/swift-style-guide ](https://github.com/linkedin/swift-style-guide)

* Airbnb Swift Style Guide - [https://github.com/airbnb/swift ](https://github.com/airbnb/swift)

### Swift Package Plugins

* WWDC 2022 Meet Swift Package plugins - [https://developer.apple.com/videos/play/wwdc2022/110359/ ](https://developer.apple.com/videos/play/wwdc2022/110359/)

* WWDC 2022 Create Swift Package plugins - [https://developer.apple.com/videos/play/wwdc2022/110401/ ](https://developer.apple.com/videos/play/wwdc2022/110401/)

* Xcode integration of Swift Package Plugins in Xcode 14 - [https://blog.eidinger.info/xcode-integration-of-swift-package-plugins-in-xcode-14 ](https://blog.eidinger.info/xcode-integration-of-swift-package-plugins-in-xcode-14)

* Beginner's guide to Swift package manager command plugins - [https://theswiftdev.com/beginners-guide-to-swift-package-manager-command-plugins/ ](https://theswiftdev.com/beginners-guide-to-swift-package-manager-command-plugins/)

* How to Use Xcode Plugins in Your iOS App - [https://betterprogramming.pub/how-to-use-xcode-plugins-in-your-ios-app-13574261f210 ](https://betterprogramming.pub/how-to-use-xcode-plugins-in-your-ios-app-13574261f210)
     
