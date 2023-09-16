//
//  SwiftLintRules.swift
//  SwiftLintPlugin
//
//  Created by Gayle Dunham on 9/18/22.
//  Copyright © 2022 Dirty Dog Software, LLC. All rights reserved.
//

import Foundation
import PackagePlugin

/// Command Plugin to run the rules subcommand on the specified Targets
@main
struct SwiftLintRules: CommandPlugin {

    /// Used by Swift Packages
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "swiftlint")
        performRulesCommand(tool: tool)
    }
}

// Required for Xcode Projects
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintRules: XcodeCommandPlugin {

    /// Used by Xcode Projects
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "swiftlint")
        performRulesCommand(tool: tool)
    }
}
#endif

extension SwiftLintRules {

    /// Configure the Tool arguments and run the Tool
    func performRulesCommand(tool: PackagePlugin.PluginContext.Tool) {
        let result = SwiftPluginTool.run(tool: tool, arguments: ["rules"])
        SwiftPluginTool.display(result: result)
    }
}
