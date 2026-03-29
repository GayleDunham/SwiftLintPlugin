//
//  SwiftPluginTool.swift
//  SwiftLintPlugin
//
//  Created by Gayle Dunham on 9/7/23.
//  Copyright © 2023-2026 Gayle Dunham
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
// NOTICE:  I duplicated this file in the following command plugins (SwiftLintFix,
//          SwiftLintLinter, and SwiftLintRules). As of Xcode 14, 15, 16, and 26,
//          I could not create a Library and use it in a plugin target in this package.
//          I tried listing the same file in multiple plugin sources array, that is
//          also not allowed. I then tried symbolic links and hard links. Xcode kills
//          hard links and does not follow symbolic links. So sad, copy and paste it is.
//

import Foundation
import PackagePlugin
import RegexBuilder

// MARK: - XcodeProject Target Support

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

enum SwiftPluginTool {

    /// The array of Target names specified in the command arguments
    static func targetsNamesFrom(arguments: [String]) -> [String] {
        stride(from: 0, to: arguments.count - 1, by: 2).compactMap {
            (arguments[$0] == "--target" ? arguments[$0 + 1] : nil)
        }
    }
}
#endif

// MARK: - Is Swift File

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

// MARK: - Configuration File Support

extension FileManager {

    /// Get the swiftlint configuration file from the current directory. Both ".swiftlint.yml"
    /// and "swiftlint.yml" file names are supported. The more visible "swiftlint.yml" is
    /// given preference if both exist.
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
            Anchor.startOfLine
            "excluded:"
            ZeroOrMore(.whitespace)
            Capture(
                OneOrMore(.any, .reluctant)
            )
            One(.newlineSequence)
            ZeroOrMore(.whitespace)
            OneOrMore(.newlineSequence)
        }
        .anchorsMatchLineEndings()

        if let match = contents?.firstMatch(of: excludeMatcher) {

            let trimmed = match.1.trimmingCharacters(in: .whitespacesAndNewlines)
            let excludes = trimmed.split(separator: "- ")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let escapedExcludes = excludes.map { NSRegularExpression.escapedPattern(for: $0) }
            let excludeRegex = try? Regex(escapedExcludes.joined(separator: "|"))
            return excludeRegex
        }

        return nil
    }
}
