//
//  Plugins.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct MacroDSLExamplePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CaseDetectionMacro.self,
    WatchDogMacro.self,
    MemberwiseInitMacro.self,
    CodingKeysMacro.self
  ]
}
