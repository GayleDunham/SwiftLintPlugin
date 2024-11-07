//
//  SwiftLintVersion.swift
//  SwiftLintPlugin
//
//  Created by Gayle Dunham on 9/7/23.
//  Copyright © 2023-2024 Dirty Dog Software, LLC. All rights reserved.
//

import Foundation
import PackagePlugin

/// Command Plugin to run the version subcommand on the specified Targets
///
/// Package Command Plug-ins are effectively scripts that are compiled each time they are executed.
///
@main
struct SwiftLintVersion: CommandPlugin {

    /// Used by Swift Packages
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "swiftlint")
        performVersionCommand(tool: tool)
    }
}

// Support for Xcode Projects
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintVersion: XcodeCommandPlugin {

    /// Used by Xcode Projects
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "swiftlint")
        performVersionCommand(tool: tool)
    }
}
#endif

extension SwiftLintVersion {

    /// Configure the Tool arguments and run the Tool
    func performVersionCommand(tool: PackagePlugin.PluginContext.Tool) {
        let result = SwiftPluginTool.run(tool: tool, arguments: ["version"])
        SwiftPluginTool.display(result: result, prefix: "swiftlint version = ")
    }
}
