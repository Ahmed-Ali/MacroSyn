//
//  TraitsReader.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

extension SyntaxReader where Node: NamedDeclSyntax {
  var name: String {
    node.name.text
  }
}

// MARK: WithAttributesSyntax trait

///  Trait-based extensions on `SyntaxReader` that provide shared functionality
///  across reader types. Each extension is constrained to a SwiftSyntax protocol
///  trait (e.g. `WithModifiersSyntax`, `WithCodeBlockSyntax`) so that any reader
///  whose node conforms automatically gains the relevant properties.
///
///  Concrete readers (StructDecl, Function, etc.) surface these via simple
///  forwarding properties, e.g. `var accessLevel: AccessLevel? { _accessLevel }`.
extension SyntaxReader where Node: WithAttributesSyntax {
  var attributes: [Attribute] {
    node.attributes.compactMap {
      Attribute($0)
    }
  }
}

// MARK: - WithModifiersSyntax trait

/// Swift access level keywords.
///
/// Used by both the Reader side (inspecting declarations) and the Builder side
/// (generating declarations with a specific access level).
public enum AccessLevel: String, Sendable {
  case `private`
  case `fileprivate`
  case `internal`
  case package
  case `public`
  case open
}

public extension SyntaxReader where Node: WithModifiersSyntax {
  var _accessLevel: AccessLevel? {
    for modifier in node.modifiers {
      switch modifier.name.tokenKind {
        case .keyword(.private): return .private
        case .keyword(.fileprivate): return .fileprivate
        case .keyword(.internal): return .internal
        case .keyword(.package): return .package
        case .keyword(.public): return .public
        case .keyword(.open): return .open
        default: continue
      }
    }
    return nil
  }

  var setterAccessLevel: AccessLevel? {
    for modifier in node.modifiers {
      guard let detail = modifier.detail else { continue }
      let detailText = detail.detail.text
      switch modifier.name.tokenKind {
        case .keyword(.private) where detailText == "set": return .private
        case .keyword(.fileprivate) where detailText == "set": return .fileprivate
        case .keyword(.internal) where detailText == "set": return .internal
        case .keyword(.package) where detailText == "set": return .package
        case .keyword(.public) where detailText == "set": return .public
        default: continue
      }
    }
    return nil
  }

  var isStatic: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
  }

  var isClass: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.class) }
  }

  var isFinal: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.final) }
  }

  var isLazy: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.lazy) }
  }

  var isWeak: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.weak) }
  }

  var isUnowned: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.unowned) }
  }

  var isMutating: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.mutating) }
  }

  var isNonmutating: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.nonmutating) }
  }

  var isOptional: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.optional) }
  }

  var isNonisolated: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.nonisolated) }
  }

  var isOverride: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.override) }
  }

  var isRequired: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.required) }
  }

  var isConvenience: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.convenience) }
  }

  var isDynamic: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.dynamic) }
  }

  var isIndirect: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.indirect) }
  }

  var isDistributed: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.distributed) }
  }

  var isConsuming: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.consuming) }
  }

  var isBorrowing: Bool {
    node.modifiers.contains { $0.name.tokenKind == .keyword(.borrowing) }
  }
}

// MARK: - WithCodeBlockSyntax trait

public extension SyntaxReader where Node: WithCodeBlockSyntax {
  var body: CodeBlock {
    CodeBlock(node.body)
  }
}

public extension CodeBlock {
  var statements: [Statement] {
    node.statements.map { Statement($0) }
  }
}

public extension Statement {
  var isDeclaration: Bool {
    node.item.is(DeclSyntax.self)
  }

  var isStatement: Bool {
    node.item.is(StmtSyntax.self)
  }

  var isExpression: Bool {
    node.item.is(ExprSyntax.self)
  }

  var asDeclaration: DeclSyntax? {
    node.item.as(DeclSyntax.self)
  }

  var asStatement: StmtSyntax? {
    node.item.as(StmtSyntax.self)
  }

  var asExpression: ExprSyntax? {
    node.item.as(ExprSyntax.self)
  }

  var description: String {
    node.item.trimmedDescription
  }
}

// MARK: - EffectSpecifiersSyntax trait

public extension SyntaxReader where Node: EffectSpecifiersSyntax {
  var isAsync: Bool {
    node.asyncSpecifier != nil
  }

  var isThrowing: Bool {
    node.throwsClause != nil
  }

  var throwingErrorType: String? {
    node.throwsClause?.type?.trimmedDescription
  }
}

// MARK: - WithSignature protocol for callables

public protocol WithSignature {
  var signature: FunctionSignatureSyntax { get }
}

extension FunctionDeclSyntax: WithSignature {}
extension InitializerDeclSyntax: WithSignature {}

public extension SyntaxReader where Node: WithSignature {
  var _parameters: [Parameter] {
    node.signature.parameterClause.parameters.map { Parameter($0) }
  }

  var _isAsync: Bool {
    node.signature.effectSpecifiers?.asyncSpecifier != nil
  }

  var _isThrowing: Bool {
    node.signature.effectSpecifiers?.throwsClause != nil
  }

  var _throwingErrorType: String? {
    node.signature.effectSpecifiers?.throwsClause?.type?.trimmedDescription
  }
}

// MARK: - ParenthesizedSyntax trait

public extension SyntaxReader where Node: ParenthesizedSyntax {
  var hasLeftParen: Bool {
    node.leftParen.presence == .present
  }

  var hasRightParen: Bool {
    node.rightParen.presence == .present
  }

  var hasBalancedParentheses: Bool {
    hasLeftParen && hasRightParen
  }

  /// The text content between the parentheses, trimmed of whitespace
  var innerContent: String {
    // Get all children between leftParen and rightParen
    var content = ""
    var foundLeft = false
    for child in node.children(viewMode: .sourceAccurate) {
      if child.id == node.leftParen.id {
        foundLeft = true
        continue
      }
      if child.id == node.rightParen.id {
        break
      }
      if foundLeft {
        content += child.trimmedDescription
      }
    }
    return content
  }
}

// MARK: - WithOptionalCodeBlockSyntax trait

public extension SyntaxReader where Node: WithOptionalCodeBlockSyntax {
  var body: CodeBlock? {
    node.body.map { CodeBlock($0) }
  }

  var hasBody: Bool {
    node.body != nil
  }
}

// MARK: - WithInheritanceClause protocol

public protocol WithInheritanceClause {
  var inheritanceClause: InheritanceClauseSyntax? { get }
}

extension AssociatedTypeDeclSyntax: WithInheritanceClause {}
extension StructDeclSyntax: WithInheritanceClause {}
extension ClassDeclSyntax: WithInheritanceClause {}
extension EnumDeclSyntax: WithInheritanceClause {}
extension ProtocolDeclSyntax: WithInheritanceClause {}
extension ActorDeclSyntax: WithInheritanceClause {}

public extension SyntaxReader where Node: WithInheritanceClause {
  var _inheritedTypes: [String] {
    node.inheritanceClause?.inheritedTypes.map(\.type.trimmedDescription) ?? []
  }

  var _primaryInheritedType: String? {
    node.inheritanceClause?.inheritedTypes.first?.type.trimmedDescription
  }
}

// MARK: - WithGenericParametersSyntax trait

public struct GenericParameter: SyntaxReader {
  public let node: GenericParameterSyntax

  public init(_ node: GenericParameterSyntax) {
    self.node = node
  }

  public var name: String {
    node.name.text
  }

  /// The constraint type (e.g., "Equatable" in `T: Equatable`)
  public var inheritedType: String? {
    node.inheritedType?.trimmedDescription
  }

  /// Whether this is a parameter pack (`each T`)
  public var isParameterPack: Bool {
    node.specifier?.tokenKind == .keyword(.each)
  }
}

public extension SyntaxReader where Node: WithGenericParametersSyntax {
  var _hasGenericParameters: Bool {
    node.genericParameterClause != nil
  }

  var _genericParameters: [GenericParameter] {
    guard let clause = node.genericParameterClause else { return [] }
    return clause.parameters.map { GenericParameter($0) }
  }
}

// MARK: - WithStatementsSyntax trait

public extension SyntaxReader where Node: WithStatementsSyntax {
  var statements: [Statement] {
    node.statements.map { Statement($0) }
  }

  var isEmpty: Bool {
    node.statements.isEmpty
  }

  var statementCount: Int {
    node.statements.count
  }
}

// MARK: - BracedSyntax trait

public extension SyntaxReader where Node: BracedSyntax {
  var hasLeftBrace: Bool {
    node.leftBrace.presence == .present
  }

  var hasRightBrace: Bool {
    node.rightBrace.presence == .present
  }

  var hasBalancedBraces: Bool {
    hasLeftBrace && hasRightBrace
  }

  /// The text content between the braces, trimmed of whitespace
  var innerContent: String {
    var content = ""
    var foundLeft = false
    for child in node.children(viewMode: .sourceAccurate) {
      if child.id == node.leftBrace.id {
        foundLeft = true
        continue
      }
      if child.id == node.rightBrace.id {
        break
      }
      if foundLeft {
        content += child.trimmedDescription
      }
    }
    return content
  }
}

// MARK: - WithTrailingCommaSyntax trait

public extension SyntaxReader where Node: WithTrailingCommaSyntax {
  var hasTrailingComma: Bool {
    node.trailingComma != nil
  }
}
