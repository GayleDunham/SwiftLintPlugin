//
//  SwiftPluginTool.swift
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

//
// NOTICE:  I duplicated this file in all the command plugins (SwiftLintFix,
//          SwiftLintLinter, SwiftLintRules, and SwiftLintVersion). As of Xcode 14, 15
//          and 16, I could not create a Library and use it in a plugin target in this
//          package. I tried listing the same file in multiple plugin sources array,
//          also not allowed. I also tried symbolic links and hard links. Xcode kills
//          hard links and does not follow symbolic links. So sad copy and paste it is.
//

import Foundation
import PackagePlugin
import RegexBuilder

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

    /// The array of Target names specified in the command arguments
    static func targetsNamesFrom(arguments: [String]) -> [String] {
        stride(from: 0, to: arguments.count - 1, by: 2).compactMap {
            (arguments[$0] == "--target" ? arguments[$0 + 1] : nil)
        }
    }
}
#endif

extension PackagePlugin.File {

    /// Determine if the file is source code and a ".swift" file
    var isSwiftFile: Bool {
        type == .source && path.isSwiftFile
    }
}

extension PackagePlugin.Path {

    /// Determine if the path ends in ".swift"
    var isSwiftFile: Bool {
        lastComponent.hasSuffix(".swift")
    }
}

extension FileManager {

    /// Get the swiftlint configuration file from the current directory. Both ".swiftlint.yml" and "swiftlint.yml"
    /// file names are supported. The more visible "swiftlint.yml" is given preference if both exist.
    var swiftlintConfigurationFile: Path {

        let root = Path(currentDirectoryPath)

        let configFile = [ "swiftlint.yml", ".swiftlint.yml"]
            .compactMap { root.appending($0) }
            .first { fileExists(atPath: $0.string) }

        guard let configFile else {
            Diagnostics.error("Error could not find config file: 'swiftlint.yml' or '.swiftlint.yml' in path: \(root)")
            exit(1)
        }

        return configFile
    }

    /// Read the swiftlint configuration file and get the exclude setting.
    func excludePaths(from configFile: Path) -> Regex<AnyRegexOutput>? {

        let contents = try? String(contentsOfFile: configFile.string, encoding: .utf8)

        let excludeMatcher = Regex {
            ZeroOrMore(.newlineSequence)
            "excluded:"
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
            let excludes = trimmed.split(separator: "- ").map( {String($0)} )

            let excludeRegex = try? Regex(excludes.joined(separator: "|"))
            return excludeRegex
        }

        return nil
    }
}
