//
//  Diagnostics.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftDiagnostics
import SwiftSyntax

// MARK: - Diagnostic Message

/// A simple diagnostic message for use in macro expansions.
public struct MacroDiagnostic: DiagnosticMessage {
  public let message: String
  public let diagnosticID: MessageID
  public let severity: DiagnosticSeverity

  public init(_ message: String, severity: DiagnosticSeverity = .error, id: String = "general") {
    self.message = message
    self.severity = severity
    diagnosticID = MessageID(domain: "MacroSyn", id: id)
  }

  public static func error(_ message: String) -> MacroDiagnostic {
    MacroDiagnostic(message, severity: .error)
  }

  public static func warning(_ message: String) -> MacroDiagnostic {
    MacroDiagnostic(message, severity: .warning)
  }

  public static func note(_ message: String) -> MacroDiagnostic {
    MacroDiagnostic(message, severity: .note)
  }
}

// MARK: - FixIt Message

/// A fix-it message for use with `DiagnosticBuilder`.
public struct MacroFixIt: FixItMessage {
  public let message: String
  public var fixItID: MessageID {
    MessageID(domain: "MacroSyn", id: "fixit")
  }

  public init(_ message: String) {
    self.message = message
  }
}

// MARK: - Diagnostic Builder

/// Fluent builder for constructing `Diagnostic` values with optional fix-its.
///
/// ```swift
/// let diag = variable
///   .error("Expected 'var'", on: variable.bindingKeyword)
///   .fix("Change to 'var'", replace: variable.bindingKeyword, with: .var)
///   .build()
/// context.diagnose(diag)
/// ```
public struct DiagnosticBuilder {
  public let node: Syntax
  public let message: MacroDiagnostic
  public var fixIts: [FixIt] = []

  public init(_ node: some SyntaxProtocol, message: MacroDiagnostic) {
    self.node = Syntax(node)
    self.message = message
  }

  public func fix(_ message: String, replace token: TokenSyntax, with keyword: Keyword) -> DiagnosticBuilder {
    var copy = self
    let newToken = token.with(\.tokenKind, .keyword(keyword))
    copy.fixIts.append(FixIt(
      message: MacroFixIt(message),
      changes: [.replace(oldNode: Syntax(token), newNode: Syntax(newToken))]))
    return copy
  }

  public func fix(_ message: String, replace token: TokenSyntax, with text: String) -> DiagnosticBuilder {
    var copy = self
    let newToken = token.with(\.tokenKind, .identifier(text))
    copy.fixIts.append(FixIt(
      message: MacroFixIt(message),
      changes: [.replace(oldNode: Syntax(token), newNode: Syntax(newToken))]))
    return copy
  }

  public func build() -> Diagnostic {
    Diagnostic(node: node, message: message, fixIts: fixIts)
  }
}

// MARK: - Ergonomic extensions on Reader types

public extension Variable {
  /// Create an error diagnostic on this variable
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  /// Create an error diagnostic on a specific part of this variable
  func error(_ message: String, on token: TokenSyntax) -> DiagnosticBuilder {
    DiagnosticBuilder(token, message: .error(message))
  }

  /// Create a warning diagnostic on this variable
  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  /// Create a warning diagnostic on a specific part
  func warning(_ message: String, on token: TokenSyntax) -> DiagnosticBuilder {
    DiagnosticBuilder(token, message: .warning(message))
  }

  /// The `let` or `var` keyword token
  var bindingKeyword: TokenSyntax {
    varSyntax.bindingSpecifier
  }
}

public extension Function {
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  func error(_ message: String, on token: TokenSyntax) -> DiagnosticBuilder {
    DiagnosticBuilder(token, message: .error(message))
  }

  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  /// The function name token
  var nameToken: TokenSyntax {
    node.name
  }

  /// The `func` keyword
  var funcKeyword: TokenSyntax {
    node.funcKeyword
  }
}

public extension Initializer {
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  func error(_ message: String, on token: TokenSyntax) -> DiagnosticBuilder {
    DiagnosticBuilder(token, message: .error(message))
  }

  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  /// The `init` keyword
  var initKeyword: TokenSyntax {
    node.initKeyword
  }

  /// The `?` or `!` if failable
  var failableMark: TokenSyntax? {
    node.optionalMark
  }
}

public extension Parameter {
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  func error(_ message: String, on token: TokenSyntax) -> DiagnosticBuilder {
    DiagnosticBuilder(token, message: .error(message))
  }

  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  /// The first name (label) token
  var firstNameToken: TokenSyntax {
    node.firstName
  }

  /// The second name token if present
  var secondNameToken: TokenSyntax? {
    node.secondName
  }
}

public extension EnumCaseDecl {
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  func error(_ message: String, on token: TokenSyntax) -> DiagnosticBuilder {
    DiagnosticBuilder(token, message: .error(message))
  }

  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  /// The case name token
  var nameToken: TokenSyntax {
    caseDecl.name
  }
}

public extension GenericParameter {
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  /// The parameter name token
  var nameToken: TokenSyntax {
    node.name
  }
}

// MARK: - Generic SyntaxReader diagnostic support

public extension SyntaxReader {
  func error(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .error(message))
  }

  func warning(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .warning(message))
  }

  func note(_ message: String) -> DiagnosticBuilder {
    DiagnosticBuilder(node, message: .note(message))
  }
}
