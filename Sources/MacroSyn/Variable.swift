//
//  Variable.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

/// Reader for a single variable binding extracted from a `VariableDeclSyntax`.
///
/// A single `var` or `let` declaration may contain multiple bindings
/// (e.g. tuple destructuring). Use `Variable.from(_:)` to get all of them.
///
/// ```swift
/// let variables = Variable.from(variableDeclSyntax)
/// variables[0].name     // "count"
/// variables[0].type     // "Int"
/// variables[0].mutable  // true
/// ```
public struct Variable: SyntaxReader {
  public let node: PatternSyntax
  public let varSyntax: VariableDeclSyntax
  public let mutable: Bool
  public let name: String
  public let type: String?
  public let value: String?

  public var isConst: Bool {
    !mutable
  }

  public var isLet: Bool {
    varSyntax.bindingSpecifier.tokenKind == .keyword(.let)
  }

  public var isVar: Bool {
    varSyntax.bindingSpecifier.tokenKind == .keyword(.var)
  }

  // MARK: - Modifiers (delegated to varSyntax)

  public var accessLevel: AccessLevel? {
    for modifier in varSyntax.modifiers {
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

  public var setterAccessLevel: AccessLevel? {
    for modifier in varSyntax.modifiers {
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

  public var isStatic: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
  }

  public var isClass: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.class) }
  }

  public var isLazy: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.lazy) }
  }

  public var isWeak: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.weak) }
  }

  public var isUnowned: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.unowned) }
  }

  public var isOverride: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.override) }
  }

  public var isFinal: Bool {
    varSyntax.modifiers.contains { $0.name.tokenKind == .keyword(.final) }
  }
}

extension Variable {
  static func from(_ v: VariableDeclSyntax) -> [Variable] {
    var res: [Variable] = []
    for binding in v.bindings {
      let mutable = v.bindingSpecifier.tokenKind == .keyword(.var) && isMutable(binding.accessorBlock)
      if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
        let instance = Variable(node: binding.pattern,
                                varSyntax: v,
                                mutable: mutable,
                                name: pattern.identifier.text,
                                type: binding.typeAnnotation?.type.trimmedDescription,
                                value: binding.initializer?.value.trimmedDescription)
        res.append(instance)
      }
      // handles cases like let (a, b) = (c, d) or let (a: String, b) = ("str", MyType())
      else if let declPatterns = binding.pattern.as(TuplePatternSyntax.self)?.elements,
              let initPatterns = binding.initializer?.value.as(
                TupleExprSyntax
                  .self)?.elements {
        if declPatterns.count != initPatterns.count {
          // TODO: This will be compiler error before it comes to the macro
          // but we should revise it later in case we need to add
          // diagnostics
          continue
        }

        // convert the abstract collections to arrays
        let (declArr, initArr) = (declPatterns.map(\.self), initPatterns.map(\.self))

        for i in 0 ..< declArr.count {
          let element = declArr[i]
          let initExpr = initArr[i]

          // Get the variable name - either from label (a: x) or pattern (x)
          let varName: String?
          if let label = element.label {
            varName = label.text
          } else if let identifierPattern = element.pattern.as(IdentifierPatternSyntax.self) {
            varName = identifierPattern.identifier.text
          } else {
            // Wildcard pattern like let (_, y) = ...
            continue
          }

          guard let name = varName else { continue }

          // Try to get type - from pattern (a: Type) or infer from initializer (Type())
          var inferredType: String?
          if element.label != nil,
             let typePattern = element.pattern.as(IdentifierPatternSyntax.self) {
            // Pattern like (a: String, b: Int) where label is name, pattern is type
            inferredType = typePattern.identifier.text
          } else if let fnc = initExpr.expression.as(FunctionCallExprSyntax.self),
                    let typeDecl = fnc.calledExpression.as(DeclReferenceExprSyntax.self) {
            // Infer type from initializer like SomeType()
            inferredType = typeDecl.baseName.text
          }

          let instance = Variable(node: binding.pattern,
                                  varSyntax: v,
                                  mutable: mutable,
                                  name: name,
                                  type: inferredType,
                                  value: initExpr.expression.trimmedDescription)
          res.append(instance)
        }
      }
    }
    return res
  }

  static func isMutable(_ a: AccessorBlockSyntax?) -> Bool {
    guard let a else { return true }
    switch a.accessors {
      case let .accessors(list):
        for accessor in list {
          let kind = accessor.accessorSpecifier.tokenKind
          if kind == .keyword(.set) || kind == .keyword(.willSet) || kind == .keyword(.didSet) {
            return true
          }
        }
        return false
      case .getter:
        return false
    }
  }
}
