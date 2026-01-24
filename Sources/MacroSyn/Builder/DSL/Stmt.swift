//
//  Stmt.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - If Statement

/// Build an if statement.
/// ```swift
/// If("condition") {
///   Return(.true)
/// } else: {
///   Return(.false)
/// }
/// ```
public func If(
  _ condition: String,
  @CodeBlockItemListBuilder then thenBody: () throws -> CodeBlockItemListSyntax,
  @CodeBlockItemListBuilder else elseBody: () throws -> CodeBlockItemListSyntax = { CodeBlockItemListSyntax([]) }
) throws -> ExprSyntax {
  let elseItems = try elseBody()
  if elseItems.isEmpty {
    return try ExprSyntax(
      IfExprSyntax("if \(raw: condition)") {
        try thenBody()
      })
  } else {
    return try ExprSyntax(
      IfExprSyntax("if \(raw: condition)") {
        try thenBody()
      } else: {
        elseItems
      })
  }
}

// MARK: - Guard Statement

/// Build a guard statement.
/// ```swift
/// Guard("let value = optional", otherwise: {
///   Return(.nil)
/// })
/// ```
public func Guard(
  _ condition: String,
  @CodeBlockItemListBuilder otherwise elseBody: () throws -> CodeBlockItemListSyntax
) throws -> StmtSyntax {
  try StmtSyntax(
    GuardStmtSyntax("guard \(raw: condition)") {
      try elseBody()
    })
}

// MARK: - Return Statement

/// Build a return statement.
/// ```swift
/// Return(.true)
/// Return(.nil)
/// Return(expr: "value + 1")
/// ```
public func Return(_ literal: Literal) -> StmtSyntax {
  StmtSyntax("return \(raw: literal.description)")
}

public func Return(expr: String) -> StmtSyntax {
  StmtSyntax("return \(raw: expr)")
}

public func Return() -> StmtSyntax {
  StmtSyntax("return")
}

// MARK: - For Statement

/// Build a for-in loop.
/// ```swift
/// For("item", in: "items") {
///   Expr("process(item)")
/// }
/// ```
public func For(
  _ pattern: String,
  in sequence: String,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> StmtSyntax {
  try StmtSyntax(
    ForStmtSyntax("for \(raw: pattern) in \(raw: sequence)") {
      try body()
    })
}

// MARK: - While Statement

/// Build a while loop.
public func While(
  _ condition: String,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> StmtSyntax {
  try StmtSyntax(
    WhileStmtSyntax("while \(raw: condition)") {
      try body()
    })
}

// MARK: - Throw Statement

/// Build a throw statement.
public func Throw(_ expression: String) -> StmtSyntax {
  StmtSyntax("throw \(raw: expression)")
}

// MARK: - Switch Statement

/// Build a switch expression.
///
/// ```swift
/// try Switch("direction") {
///   SwitchCase("case .north:") {
///     Return(expr: "\"up\"")
///   }
///   SwitchCase("default:") {
///     Return(expr: "\"unknown\"")
///   }
/// }
/// ```
public func Switch(
  _ expression: String,
  @SwitchCaseListBuilder cases: () throws -> SwitchCaseListSyntax
) throws -> ExprSyntax {
  try ExprSyntax(
    SwitchExprSyntax("switch \(raw: expression)") {
      try cases()
    })
}

/// Build a single switch case.
///
/// ```swift
/// SwitchCase("case .north:") { ... }
/// ```
public func SwitchCase(
  _ label: String,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> SwitchCaseSyntax {
  try SwitchCaseSyntax("\(raw: label)") {
    try body()
  }
}

// MARK: - Do/Catch Statement

/// Build a do-catch statement.
///
/// ```swift
/// try Do {
///   "try riskyOperation()"
/// } catch: {
///   try Catch {
///     "print(error)"
///   }
/// }
/// ```
public func Do(
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax,
  @CatchClauseListBuilder catch catchClauses: () throws -> CatchClauseListSyntax
) throws -> StmtSyntax {
  let doBody = try body()
  let catches = try catchClauses()
  return StmtSyntax(
    DoStmtSyntax(
      body: CodeBlockSyntax(statements: doBody),
      catchClauses: catches))
}

/// Build a catch clause.
///
/// ```swift
/// Catch("let error as NetworkError") { ... }
/// Catch { ... }  // bare catch
/// ```
public func Catch(
  _ pattern: String? = nil,
  @CodeBlockItemListBuilder body: () throws -> CodeBlockItemListSyntax
) throws -> CatchClauseSyntax {
  if let pattern {
    return try CatchClauseSyntax("catch \(raw: pattern)") {
      try body()
    }
  }
  return try CatchClauseSyntax("catch") {
    try body()
  }
}
