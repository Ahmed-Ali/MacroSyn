//
//  Decl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - Type Reference

/// Common type references for declaration builders.
public struct TypeRef: Sendable {
  public let name: String

  private init(_ name: String) {
    self.name = name
  }

  // Primitives
  public static let bool = TypeRef("Bool")
  public static let int = TypeRef("Int")
  public static let double = TypeRef("Double")
  public static let float = TypeRef("Float")
  public static let string = TypeRef("String")
  public static let void = TypeRef("Void")
  public static let any = TypeRef("Any")

  // Common types
  public static let data = TypeRef("Data")
  public static let date = TypeRef("Date")
  public static let url = TypeRef("URL")
  public static let error = TypeRef("Error")

  /// Constructors
  public static func custom(_ name: String) -> TypeRef {
    TypeRef(name)
  }

  public static func array(of element: TypeRef) -> TypeRef {
    TypeRef("[\(element.name)]")
  }

  public static func array(of element: String) -> TypeRef {
    TypeRef("[\(element)]")
  }

  public static func dict(key: TypeRef, value: TypeRef) -> TypeRef {
    TypeRef("[\(key.name): \(value.name)]")
  }

  public static func optional(_ wrapped: TypeRef) -> TypeRef {
    TypeRef("\(wrapped.name)?")
  }

  public static func optional(_ wrapped: String) -> TypeRef {
    TypeRef("\(wrapped)?")
  }

  public static func result(success: TypeRef, failure: TypeRef = .error) -> TypeRef {
    TypeRef("Result<\(success.name), \(failure.name)>")
  }
}

// MARK: - Computed Property

/// Build a computed variable declaration.
/// ```swift
/// Var("isActive", type: .bool) {
///   Return(.true)
/// }
/// ```
public func Var(
  _ name: String,
  type: TypeRef,
  access: AccessLevel? = nil,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> DeclSyntax {
  let accessPrefix = access.map { "\($0.rawValue) " } ?? ""
  return try DeclSyntax(
    VariableDeclSyntax("\(raw: accessPrefix)var \(raw: name): \(raw: type.name)") {
      try body()
    })
}

// MARK: - Stored Property

/// Build a stored variable declaration.
/// ```swift
/// StoredVar("count", type: .int, value: .zero)
/// ```
public func StoredVar(
  _ name: String,
  type: TypeRef,
  value: Literal? = nil,
  isLet: Bool = false,
  access: AccessLevel? = nil
) -> DeclSyntax {
  let accessPrefix = access.map { "\($0.rawValue) " } ?? ""
  let keyword = isLet ? "let" : "var"
  let valueSuffix = value.map { " = \($0.description)" } ?? ""
  return DeclSyntax(stringLiteral: "\(accessPrefix)\(keyword) \(name): \(type.name)\(valueSuffix)")
}

// MARK: - Function (Legacy API)

/// Build a function declaration.
///
/// - Note: Prefer the new `Func(_:_:access:static:async:throws:)` → `FuncBuilder` API.
@available(*, deprecated, message: "Use the new Func() -> FuncBuilder API with Arg parameters")
public func Func(
  _ name: String,
  params: [(String, TypeRef)] = [],
  returns: TypeRef? = nil,
  access: AccessLevel? = nil,
  isStatic: Bool = false,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> DeclSyntax {
  var prefixes: [String] = []
  if let access { prefixes.append(access.rawValue) }
  if isStatic { prefixes.append("static") }
  let prefix = prefixes.isEmpty ? "" : prefixes.joined(separator: " ") + " "

  let paramStr = params.map { "\($0.0): \($0.1.name)" }.joined(separator: ", ")
  let returnStr = returns.map { " -> \($0.name)" } ?? ""

  return try DeclSyntax(
    FunctionDeclSyntax("\(raw: prefix)func \(raw: name)(\(raw: paramStr))\(raw: returnStr)") {
      try body()
    })
}

// MARK: - Function (New API)

/// Intermediate builder returned by `Func(...)`. Terminate with `.returns(...)` or `.body(...)`.
public struct FuncBuilder: Sendable {
  let name: String
  let args: [Arg]
  let access: AccessLevel?
  let isStatic: Bool
  let isAsync: Bool
  let isThrowing: Bool

  /// Build a function with a return type and body.
  public func returns(
    _ type: TypeRef,
    @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
  ) throws -> DeclSyntax {
    try buildDecl(returnType: type, body: body)
  }

  /// Build a void function with a body.
  public func body(
    @CodeBlockItemListBuilder _ body: () throws -> CodeBlockItemListSyntax
  ) throws -> DeclSyntax {
    try buildDecl(returnType: nil, body: body)
  }

  private func buildDecl(
    returnType: TypeRef?,
    body: () throws -> CodeBlockItemListSyntax
  ) throws -> DeclSyntax {
    var prefixes: [String] = []
    if let access { prefixes.append(access.rawValue) }
    if isStatic { prefixes.append("static") }
    let prefix = prefixes.isEmpty ? "" : prefixes.joined(separator: " ") + " "

    let paramStr = args.map(\.parameterString).joined(separator: ", ")

    var effectStr = ""
    if isAsync { effectStr += " async" }
    if isThrowing { effectStr += " throws" }

    let returnStr = returnType.map { " -> \($0.name)" } ?? ""

    return try DeclSyntax(
      FunctionDeclSyntax("\(raw: prefix)func \(raw: name)(\(raw: paramStr))\(raw: effectStr)\(raw: returnStr)") {
        try body()
      })
  }
}

/// Create a function builder. Terminate with `.returns(type) { ... }` or `.body { ... }`.
///
/// ```swift
/// try Func("fetch", Arg("url", type: URL.self), async: true, throws: true)
///   .returns(.data) {
///     Return(expr: "try await URLSession.shared.data(from: url)")
///   }
/// ```
public func Func(
  _ name: String,
  _ args: Arg...,
  access: AccessLevel? = nil,
  static isStatic: Bool = false,
  async isAsync: Bool = false,
  throws isThrowing: Bool = false
) -> FuncBuilder {
  FuncBuilder(
    name: name,
    args: args,
    access: access,
    isStatic: isStatic,
    isAsync: isAsync,
    isThrowing: isThrowing)
}

// MARK: - Initializer

/// Build an initializer declaration.
///
/// ```swift
/// try Init(Arg("name", type: String.self), access: .public) {
///   "self.name = name"
/// }
/// ```
public func Init(
  _ args: Arg...,
  access: AccessLevel? = nil,
  failable: Bool = false,
  async isAsync: Bool = false,
  throws isThrowing: Bool = false,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> DeclSyntax {
  try Init(args, access: access, failable: failable, async: isAsync, throws: isThrowing, body: body)
}

/// Array-based overload for programmatic use (e.g. generating args from parsed properties).
public func Init(
  _ args: [Arg],
  access: AccessLevel? = nil,
  failable: Bool = false,
  async isAsync: Bool = false,
  throws isThrowing: Bool = false,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> DeclSyntax {
  let accessPrefix = access.map { "\($0.rawValue) " } ?? ""
  let failableSuffix = failable ? "?" : ""
  let paramStr = args.map(\.parameterString).joined(separator: ", ")

  var effectStr = ""
  if isAsync { effectStr += " async" }
  if isThrowing { effectStr += " throws" }

  return try DeclSyntax(
    InitializerDeclSyntax("\(raw: accessPrefix)init\(raw: failableSuffix)(\(raw: paramStr))\(raw: effectStr)") {
      try body()
    })
}
