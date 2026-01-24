//
//  TypeDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 13/02/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - Struct

/// Build a struct declaration.
///
/// ```swift
/// try Struct("User", access: .public, inherits: ["Codable"]) {
///   StoredVar("name", type: .string)
///   StoredVar("age", type: .int)
/// }
/// ```
public func Struct(
  _ name: String,
  access: AccessLevel? = nil,
  inherits: [String] = [],
  @MemberBlockItemListBuilder members: () throws -> MemberBlockItemListSyntax
) throws -> DeclSyntax {
  let accessPrefix = access.map { "\($0.rawValue) " } ?? ""
  let inheritanceClause = inherits.isEmpty ? "" : ": \(inherits.joined(separator: ", "))"

  return try DeclSyntax(
    StructDeclSyntax("\(raw: accessPrefix)struct \(raw: name)\(raw: inheritanceClause)") {
      try members()
    })
}

// MARK: - Class

/// Build a class declaration.
///
/// ```swift
/// try Class("ViewModel", access: .public, inherits: ["ObservableObject"]) {
///   StoredVar("title", type: .string, value: .string(""))
/// }
/// ```
public func Class(
  _ name: String,
  access: AccessLevel? = nil,
  inherits: [String] = [],
  @MemberBlockItemListBuilder members: () throws -> MemberBlockItemListSyntax
) throws -> DeclSyntax {
  let accessPrefix = access.map { "\($0.rawValue) " } ?? ""
  let inheritanceClause = inherits.isEmpty ? "" : ": \(inherits.joined(separator: ", "))"

  return try DeclSyntax(
    ClassDeclSyntax("\(raw: accessPrefix)class \(raw: name)\(raw: inheritanceClause)") {
      try members()
    })
}

// MARK: - Enum

/// Build an enum declaration.
///
/// ```swift
/// try Enum("Direction", inherits: ["String"]) {
///   Case("north")
///   Case("south")
/// }
/// ```
public func Enum(
  _ name: String,
  access: AccessLevel? = nil,
  inherits: [String] = [],
  @MemberBlockItemListBuilder members: () throws -> MemberBlockItemListSyntax
) throws -> DeclSyntax {
  let accessPrefix = access.map { "\($0.rawValue) " } ?? ""
  let inheritanceClause = inherits.isEmpty ? "" : ": \(inherits.joined(separator: ", "))"

  return try DeclSyntax(
    EnumDeclSyntax("\(raw: accessPrefix)enum \(raw: name)\(raw: inheritanceClause)") {
      try members()
    })
}

// MARK: - Extension

/// Build an extension declaration.
///
/// ```swift
/// try Extension("User", conformingTo: ["CustomStringConvertible"]) {
///   try Var("description", type: .string) {
///     Return(expr: "name")
///   }
/// }
/// ```
public func Extension(
  _ typeName: String,
  conformingTo protocols: [String] = [],
  @MemberBlockItemListBuilder members: () throws -> MemberBlockItemListSyntax
) throws -> DeclSyntax {
  let conformanceClause = protocols.isEmpty ? "" : ": \(protocols.joined(separator: ", "))"

  return try DeclSyntax(
    ExtensionDeclSyntax("extension \(raw: typeName)\(raw: conformanceClause)") {
      try members()
    })
}

// MARK: - Enum Case

/// Build a simple enum case, optionally with a raw value.
///
/// ```swift
/// Case("north")
/// Case("north", rawValue: "\"N\"")
/// ```
public func Case(_ name: String, rawValue: String? = nil) -> DeclSyntax {
  if let rawValue {
    return DeclSyntax(stringLiteral: "case \(name) = \(rawValue)")
  }
  return DeclSyntax(stringLiteral: "case \(name)")
}

/// Build an enum case with associated values.
///
/// ```swift
/// Case("error", args: (nil, "String"), ("code", "Int"))
/// // -> case error(String, code: Int)
/// ```
public func Case(_ name: String, args: (String?, String)...) -> DeclSyntax {
  let paramStr = args.map { label, type in
    if let label {
      return "\(label): \(type)"
    }
    return type
  }.joined(separator: ", ")
  return DeclSyntax(stringLiteral: "case \(name)(\(paramStr))")
}
