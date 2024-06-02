//
//  SwiftPluginTool.swift
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

//
// NOTICE:  I duplicated this file in all the command plugins (SwiftLintFix,
//          SwiftLintLinter, SwiftLintRules, and SwiftLintVersion). As of Xcode 14
//          and 15, I could not create a Library and use it in a plugin target
//          in this package. I also tried listing the same file in multiple plugin
//          sources array, also not allowed.
//

import Foundation
import PackagePlugin

enum SwiftPluginTool {

    /// Run the Tool and return a `Result`
    static func run(tool: PackagePlugin.PluginContext.Tool, arguments: [String]) -> Result<String, ToolError> {

        let toolUrl = URL(fileURLWithPath: tool.path.string)

        let task = Process()
        task.executableURL = toolUrl
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe

        try? task.run()
        task.waitUntilExit()

        // Check for errors in the subprocess.
        if task.terminationReason != .exit || task.terminationStatus != 0 {

            let problem = "\(task.terminationReason):\(task.terminationStatus)"
            let message = "swiftlint invocation failed: \(problem)"
            return .failure(.runFailed(message))
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        return .success(output ?? "")
    }

    /// Display the result of running the command
    static func display(result: Result<String, ToolError>, prefix: String = "") {
        switch result {
        case .success(let message):
            print("\(prefix)\(message)")
        case .failure(let error):
            Diagnostics.error(error.localizedDescription)
        }
    }

    /// `ToolError` is the `Error` Type used for returned `Result`
    enum ToolError: Error, LocalizedError {
        case runFailed(String)

        public var errorDescription: String? {
            switch self {
            case .runFailed(let problem):
                return NSLocalizedString("swiftlint invocation failed: \(problem)", comment: "")
            }
        }
    }

}

// MARK: - XcodeProject Target Support

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftPluginTool {

    /// The array of Target directories for the targets the user selected as supplied by the arguments list.
    static func targetsDirectories(arguments: [String], projectTargets: [XcodeProjectPlugin.XcodeTarget]) -> [String] {

        let targetNames = SwiftPluginTool.targetsNamesFrom(arguments: arguments)

        let targetDirectories = projectTargets
            .filter { targetNames.contains($0.displayName) }
            .compactMap { targetsDirectory(fileList: $0.inputFiles) }

        return targetDirectories
    }

    /// The array of Target names specified in the command arguments
    static func targetsNamesFrom(arguments: [String]) -> [String] {
        stride(from: 0, to: arguments.count - 1, by: 2).compactMap {
            (arguments[$0] == "--target" ? arguments[$0 + 1] : nil)
        }
    }

    /// The directory found from the Target FileList that contains all the source files.
    static func targetsDirectory(fileList: FileList) -> String {

        let currentDirectory = FileManager.default.currentDirectoryPath
        let path = (fileList.first { _ in true })?.path.removingLastComponent()

        guard var path else {
            Diagnostics.error("Unable to get a path from the FileList: \(fileList)")
            exit(1)
        }

        let sourceFiles = fileList.filter { $0.type == .source }

        var foundIt = false
        var tries = 0
        repeat {
            foundIt = sourceFiles.allSatisfy { $0.path.string.contains(path.string) }

            if !foundIt {
                path = path.removingLastComponent()
                tries += 1
            }

        } while (!foundIt || tries > 20 || currentDirectory == path.string )

        return path.string
    }

}
#endif
