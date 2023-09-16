//
//  SwiftLintBuildTool.swift
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

@main
struct SwiftLintBuildTool: BuildToolPlugin {

    // Used by Swift Packages
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectory.appending("swiftlint")
        let directory = target.directory.string

        return createPreBuildCommands(tool: tool, outputDirectory: outputDirectory, targetDirectory: directory)
    }
}

// Required for Xcode Projects
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintBuildTool: XcodeBuildToolPlugin {

    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectory.appending("swiftlint")
        let directory = SwiftPluginTool.targetsDirectory(fileList: target.inputFiles)

        return createPreBuildCommands(tool: tool, outputDirectory: outputDirectory, targetDirectory: directory)
    }
}
#endif

extension SwiftLintBuildTool {

    func createPreBuildCommands(tool: PackagePlugin.PluginContext.Tool, outputDirectory: PackagePlugin.Path,
                                targetDirectory: String) -> [Command] {

        let currentDirectory = FileManager.default.currentDirectoryPath
        let configFile = findConfigurationFileIn(path: Path(currentDirectory))

        return [
            .prebuildCommand(
                displayName: "SwiftLint BuildTool Plugin",
                executable: tool.path,
                arguments: [
                    "lint", "--config", configFile.string,
                    "--cache-path", outputDirectory.appending("cache").string,
                    targetDirectory
                ],
                outputFilesDirectory: outputDirectory
            )
        ]
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
