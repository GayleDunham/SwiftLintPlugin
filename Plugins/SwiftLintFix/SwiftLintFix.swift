//
//  SwiftLintFix.swift
//  SwiftLintPlugin
//
//  Created by Gayle Dunham on 9/7/23.
//  Copyright © 2023-2024 Gayle Dunham
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

/// Command Plugin to run the lint --fix subcommand on the specified Targets
///
/// Package Command Plug-ins are effectively scripts that are compiled each time they are executed.
///
@main
struct SwiftLintFix: CommandPlugin {

    /// Used by Swift Packages
    func performCommand(context: PluginContext, arguments: [String]) async throws {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectoryURL.appendingPathComponent("swiftlint")
        let targets = context.package.targets.compactMap { $0 as? SwiftSourceModuleTarget }
        let directories = targets.map(\.directoryURL.relativePath)

        performFixCommand(tool: tool, outputDirectory: outputDirectory, inputPaths: directories)
    }

}

// Support for Xcode Projects
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintFix: XcodeCommandPlugin {

    /// Used by Xcode Projects
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectoryURL.appendingPathComponent("swiftlint")

        let targetNames = SwiftPluginTool.targetsNamesFrom(arguments: arguments)
        let selectedTargets = context.xcodeProject.targets.filter { targetNames.contains($0.displayName) }

        let flattenedInputFiles = selectedTargets.compactMap(\.inputFiles).reduce([], +)
        let swiftFiles = flattenedInputFiles.filter(\File.isSwiftFile).map(\.url.relativePath)

        performFixCommand(tool: tool, outputDirectory: outputDirectory, inputPaths: swiftFiles)
    }
}
#endif

extension SwiftLintFix {

    /// Configure the Tool arguments and run the Tool
    func performFixCommand(tool: PackagePlugin.PluginContext.Tool, outputDirectory: URL,
                           inputPaths: [String]) {

        var lintPaths = inputPaths
        let configFile = FileManager.default.swiftlintConfigurationFile

        if let excludes = FileManager.default.excludePaths(from: configFile) {
            lintPaths = inputPaths.filter { !$0.contains(excludes) }
        }

        let lintArgs = [
            "lint", "--fix",
            "--cache-path", outputDirectory.appendingPathComponent("cache").relativePath,
            "--config", FileManager.default.swiftlintConfigurationFile
        ] + lintPaths

        let result = SwiftPluginTool.run(tool: tool, arguments: lintArgs)
        SwiftPluginTool.display(result: result)
    }
}
