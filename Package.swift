// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "MacroSyn",
  platforms: [
    .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)
  ],
  products: [
    .library(
      name: "MacroSyn",
      targets: ["MacroSyn"])

  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest")
  ],
  targets: [
    .target(
      name: "MacroSyn",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ],
      path: "Sources/MacroSyn"),

    .macro(
      name: "ExamplesMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        "MacroSyn"
      ],
      path: "Sources/Examples/Macros"),

    .target(
      name: "ExampleLibrary",
      dependencies: ["ExamplesMacros"],
      path: "Sources/Examples/Interfaces"),

    .executableTarget(
      name: "Demo",
      dependencies: [
        "ExampleLibrary"
      ]),

    .testTarget(
      name: "MacroSynTests",
      dependencies: ["MacroSyn",
                     .product(
                       name: "SwiftSyntaxMacrosTestSupport",
                       package: "swift-syntax")],
      path: "Tests/MacroSynTests")
  ])
