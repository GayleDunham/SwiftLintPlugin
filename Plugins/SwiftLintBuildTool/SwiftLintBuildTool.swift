//
//  SwiftLintBuildTool.swift
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
import RegexBuilder

/// Swift Package Build Tool Plug-in to run Swiftlint on a `Target`.
///
/// Package Build Tool Plug-ins are effectively scripts that are compiled, applied to a target to
/// create a `PackagePlugin.Command`, then the `Command` is executed. The compile, apply and execute actions are
/// performed each build.
///
@main
struct SwiftLintBuildTool: BuildToolPlugin {

    /// Called by Swift Packages
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectoryURL.appendingPathComponent("swiftlint")
        let directory = (target as? SwiftSourceModuleTarget)?.directoryURL.relativePath ?? "."

        return createPreBuildCommands(tool: tool, outputDirectory: outputDirectory, inputPaths: [directory])
    }
}

// Support for Xcode Projects
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintBuildTool: XcodeBuildToolPlugin {

    /// Called by Xcode Project Build Phases "Run Build Tool Plug-ins"
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {

        let tool = try context.tool(named: "swiftlint")
        let outputDirectory = context.pluginWorkDirectoryURL.appendingPathComponent("swiftlint")
        let swiftFiles = target.inputFiles.filter(\.isSwiftFile).compactMap(\.url.relativePath)

        return createPreBuildCommands(tool: tool, outputDirectory: outputDirectory, inputPaths: swiftFiles)
    }
}
#endif

extension SwiftLintBuildTool {

    /// Function to create the Prebuild Command that the Build Phase will execute
    func createPreBuildCommands(tool: PackagePlugin.PluginContext.Tool, outputDirectory: URL,
                                inputPaths: [String]) -> [Command] {

        var lintFiles = inputPaths
        let configFile = FileManager.default.swiftlintConfigurationFile

        if let excludes = FileManager.default.excludePaths(from: configFile) {
            lintFiles = inputPaths.filter { !$0.contains(excludes) }
        }

        guard !lintFiles.isEmpty else {
            Diagnostics.error("Error the list of files to lint is empty.")
            exit(2)
        }

        return [
            .prebuildCommand(
                displayName: "SwiftLint BuildTool Plugin",
                executable: tool.url,
                arguments: [
                    "lint",
                    "--config", configFile,
                    "--cache-path", outputDirectory.appendingPathComponent("cache").relativePath
                ] + lintFiles,
                outputFilesDirectory: outputDirectory
            )
        ]
    }

}

extension PackagePlugin.File {

    /// Determine if the file is source code and a ".swift" file
    var isSwiftFile: Bool {
        type == .source && url.isSwiftFile
    }
}

extension URL {

    /// Determine if the is a file and has the extension swift
    var isSwiftFile: Bool {
        isFileURL && pathExtension == "swift"
    }
}

extension FileManager {

    /// Get the swiftlint configuration file from the current directory. Both ".swiftlint.yml" and "swiftlint.yml"
    /// file names are supported. The more visible "swiftlint.yml" is given preference if both exist.
    var swiftlintConfigurationFile: String {

        let configFile = [ "/swiftlint.yml", "/.swiftlint.yml"]
            .compactMap { currentDirectoryPath + $0 }
            .first { fileExists(atPath: $0) }

        guard let configFile else {
            Diagnostics.error("""
            Error could not find config file: 'swiftlint.yml' or '.swiftlint.yml' in path: \(currentDirectoryPath)
            """)
            exit(1)
        }

        return configFile
    }

    /// Read the swiftlint configuration file and get the exclude setting.
    func excludePaths(from configFile: String) -> Regex<AnyRegexOutput>? {

        let contents = try? String(contentsOfFile: configFile, encoding: .utf8)

        let excludeMatcher = Regex {
            ZeroOrMore(.newlineSequence)
            #"[^\h]excluded:"#
            ZeroOrMore(.whitespace)
            Capture(
                OneOrMore(.any, .reluctant)
            )
            One(.newlineSequence)
            ZeroOrMore(.whitespace)
            OneOrMore(.newlineSequence)
        }

        if let match = contents?.firstMatch(of: excludeMatcher) {

            let trimmed = match.1.trimmingCharacters(in: .whitespacesAndNewlines)
            let excludes = trimmed.split(separator: "- ").map { String($0) }

            let excludeRegex = try? Regex(excludes.joined(separator: "|"))
            return excludeRegex
        }

        return nil
    }
}
