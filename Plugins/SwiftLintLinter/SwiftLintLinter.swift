//
//  SwiftLintLinter.swift
//  SwiftLintPlugin
//
//  Created by Gayle Dunham on 9/7/23.
//  Copyright © 2023 Gayle Dunham
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import PackagePlugin

/// Command Plugin to run the lint subcommand on the specified Targets
@main
struct SwiftLintLinter: CommandPlugin {

    /// Used by Swift Packages
    func performCommand(context: PluginContext, arguments: [String]) async throws {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectory.appending("swiftlint")
        let directories = context.package.targets.compactMap { $0.directory.string }

        performLintCommand(tool: tool, outputDirectory: outputDirectory, targetDirectories: directories)
    }

}

// Required for Xcode Projects
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintLinter: XcodeCommandPlugin {

    /// Used by Xcode Projects
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectory.appending("swiftlint")
        let targets = context.xcodeProject.targets
        let directories = SwiftPluginTool.targetsDirectories(arguments: arguments, projectTargets: targets)

        performLintCommand(tool: tool, outputDirectory: outputDirectory, targetDirectories: directories)
    }
}
#endif

extension SwiftLintLinter {

    /// Configure the Tool arguments and run the Tool
    func performLintCommand(tool: PackagePlugin.PluginContext.Tool, outputDirectory: PackagePlugin.Path,
                            targetDirectories: [String]) {

        let configFile = findConfigurationFileIn(path: Path(FileManager.default.currentDirectoryPath))

        let lintArgs: [String] = [
            "lint",
            "--cache-path", outputDirectory.appending("cache").string,
            "--config", configFile.string
        ] + targetDirectories

        let result = SwiftPluginTool.run(tool: tool, arguments: lintArgs)
        SwiftPluginTool.display(result: result)
    }

    /// Find the swiftlint configuration file
    func findConfigurationFileIn(path: Path) -> Path {

        let configFile = [ "swiftlint.yml", ".swiftlint.yml"]
            .compactMap { path.appending($0) }
            .first { FileManager.default.fileExists(atPath: $0.string) }

        guard let configFile else {
           Diagnostics.error("Error could not find config file: 'swiftlint.yml' or '.swiftlint.yml' in path: \(path)")
            exit(1)
        }

        return configFile
    }

}
