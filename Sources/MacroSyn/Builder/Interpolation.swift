//
//  Interpolation.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - Named declarations

public extension SyntaxStringInterpolation {
  /// Interpolate a named declaration by its name
  mutating func appendInterpolation<T: SyntaxReader>(
    _ reader: T
  ) where T.Node: NamedDeclSyntax {
    appendInterpolation(raw: reader.node.name.text)
  }
}

// MARK: - Property/Variable

public extension SyntaxStringInterpolation {
  /// Interpolate a property by its name
  mutating func appendInterpolation(_ property: Property) {
    appendInterpolation(raw: property.name)
  }

  /// Interpolate a property's type
  mutating func appendInterpolation(typeOf property: Property) {
    if let type = property.type {
      appendInterpolation(raw: type)
    }
  }
}

// MARK: - Parameter

public extension SyntaxStringInterpolation {
  /// Interpolate a parameter's local name (the name used in the function body)
  mutating func appendInterpolation(_ parameter: Parameter) {
    appendInterpolation(raw: parameter.localName)
  }

  /// Interpolate a parameter's type
  mutating func appendInterpolation(typeOf parameter: Parameter) {
    appendInterpolation(raw: parameter.type)
  }

  /// Interpolate a full parameter declaration (for generating function signatures)
  mutating func appendInterpolation(declaration parameter: Parameter) {
    let label = parameter.label
    if let secondName = parameter.secondName {
      appendInterpolation(raw: "\(label) \(secondName): \(parameter.type)")
    } else {
      appendInterpolation(raw: "\(label): \(parameter.type)")
    }
  }
}

// MARK: - GenericParameter

public extension SyntaxStringInterpolation {
  /// Interpolate a generic parameter by its name
  mutating func appendInterpolation(_ param: GenericParameter) {
    appendInterpolation(raw: param.name)
  }
}

// MARK: - EnumCaseDecl

public extension SyntaxStringInterpolation {
  /// Interpolate an enum case by its name
  mutating func appendInterpolation(_ enumCase: EnumCaseDecl) {
    appendInterpolation(raw: enumCase.name)
  }
}

// MARK: - AssociatedType

public extension SyntaxStringInterpolation {
  /// Interpolate an associated type by its name
  mutating func appendInterpolation(_ assocType: AssociatedType) {
    appendInterpolation(raw: assocType.name)
  }
}

// MARK: - AccessLevel

public extension SyntaxStringInterpolation {
  /// Interpolate an access level keyword
  mutating func appendInterpolation(_ accessLevel: AccessLevel) {
    appendInterpolation(raw: accessLevel.rawValue)
  }

  /// Interpolate an optional access level with trailing space if present
  mutating func appendInterpolation(_ accessLevel: AccessLevel?) {
    if let level = accessLevel {
      appendInterpolation(raw: level.rawValue + " ")
    }
  }
}
