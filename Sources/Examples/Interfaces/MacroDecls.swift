//
//  MacroDecls.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

@attached(member, names: arbitrary)
public macro CaseDetection() =
  #externalMacro(module: "ExamplesMacros", type: "CaseDetectionMacro")

@attached(body)
public macro Watch(_: String...) =
  #externalMacro(module: "ExamplesMacros", type: "WatchDogMacro")

@attached(member, names: named(init))
public macro MemberwiseInit() =
  #externalMacro(module: "ExamplesMacros", type: "MemberwiseInitMacro")

@attached(member, names: named(CodingKeys))
public macro CustomCodingKeys() =
  #externalMacro(module: "ExamplesMacros", type: "CodingKeysMacro")
