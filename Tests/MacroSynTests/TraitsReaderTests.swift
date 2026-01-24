//
//  TraitsReaderTests.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

@testable import MacroSyn
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import Testing

@Suite struct TraitsReaderTests {
  // MARK: - Variable Parsing

  @Test func tupleDestructuring() {
    let syntax = "let (x, y) = (SomeType(), AnotherType())".asVariableDecl
    let variables = Variable.from(syntax)

    #expect(variables.count == 2)
    #expect(variables[0].name == "x")
    #expect(variables[0].type == "SomeType")
    #expect(variables[1].name == "y")
    #expect(variables[1].type == "AnotherType")
  }

  @Test func computedPropertyMutability() {
    let getOnly = """
    var value: Int { get { 0 } }
    """.asVariableDecl
    let getSet = """
    var value: Int { get { 0 } set { } }
    """.asVariableDecl
    let withDidSet = """
    var value: Int { didSet { } }
    """.asVariableDecl

    #expect(Variable.from(getOnly)[0].mutable == false)
    #expect(Variable.from(getSet)[0].mutable == true)
    #expect(Variable.from(withDidSet)[0].mutable == true)
  }

  @Test func declGroupVariables() {
    let syntax = """
    struct Container {
      let id: Int
      var name: String
    }
    """.asStructDecl
    let reader = StructDecl(syntax)
    let vars = reader.properties

    #expect(vars.count == 2)
    #expect(vars[0].name == "id")
    #expect(vars[0].mutable == false)
    #expect(vars[1].name == "name")
    #expect(vars[1].mutable == true)
  }

  // MARK: - Access Level Parsing

  @Test func setterAccessLevel() {
    let syntax = "public private(set) var value: Int".asVariableDecl
    let variables = Variable.from(syntax)

    #expect(variables[0].accessLevel == .public)
    #expect(variables[0].setterAccessLevel == .private)
  }

  // MARK: - Effect Specifiers

  @Test func typedThrows() {
    let syntax = "func fetch() throws(NetworkError) -> Data".asFunctionDecl
    let fn = Function(syntax)

    #expect(fn.isThrowing == true)
    #expect(fn.throwingErrorType == "NetworkError")
  }

  // MARK: - Generic Parameters

  @Test func genericParametersWithConstraints() {
    let syntax = "struct Container<T, U: Equatable, each V> {}".asStructDecl
    let reader = StructDecl(syntax)
    let params = reader.genericParameters

    #expect(params.count == 3)
    #expect(params[0].name == "T")
    #expect(params[0].inheritedType == nil)
    #expect(params[1].name == "U")
    #expect(params[1].inheritedType == "Equatable")
    #expect(params[2].name == "V")
    #expect(params[2].isParameterPack == true)
  }

  // MARK: - Function & Parameter

  @Test func functionParameterNames() {
    let syntax = "func update(for id: Int, _ value: String, name: String) {}".asFunctionDecl
    let fn = Function(syntax)
    let params = fn.parameters

    #expect(params[0].label == "for")
    #expect(params[0].secondName == "id")
    #expect(params[0].localName == "id")

    #expect(params[1].label == "_")
    #expect(params[1].secondName == "value")
    #expect(params[1].localName == "value")

    #expect(params[2].label == "name")
    #expect(params[2].secondName == nil)
    #expect(params[2].localName == "name")
  }

  // MARK: - Initializer

  @Test func failableInitializer() {
    let regular = "init(value: Int) {}".asInitializerDecl
    let failable = "init?(value: Int) {}".asInitializerDecl
    let implicitUnwrap = "init!(value: Int) {}".asInitializerDecl

    #expect(Initializer(regular).isFailable == false)
    #expect(Initializer(failable).isFailable == true)
    #expect(Initializer(failable).isImplicitlyUnwrapped == false)
    #expect(Initializer(implicitUnwrap).isFailable == true)
    #expect(Initializer(implicitUnwrap).isImplicitlyUnwrapped == true)
  }

  // MARK: - Property

  @Test func propertyWithTraits() {
    let syntax = "public static let value: Int = 42".asVariableDecl
    let prop = Property.from(syntax)[0]

    #expect(prop.accessLevel == .public)
    #expect(prop.isStatic == true)
    #expect(prop.isLet == true)
    #expect(prop.name == "value")
  }

  // MARK: - Enum Cases

  @Test func enumCasesWithAssociatedValues() {
    let syntax = """
    enum Result {
      case success(value: Int)
      case failure(Error)
      case empty
    }
    """.asEnumDecl
    let reader = EnumDecl(syntax)
    let cases = reader.cases

    #expect(cases.count == 3)
    #expect(cases[0].name == "success")
    #expect(cases[0].hasAssociatedValues == true)
    #expect(cases[0].associatedValues[0].label == "value")
    #expect(cases[0].associatedValues[0].type == "Int")

    #expect(cases[1].name == "failure")
    #expect(cases[1].associatedValues[0].label == nil)

    #expect(cases[2].name == "empty")
    #expect(cases[2].hasAssociatedValues == false)
  }

  // MARK: - Diagnostics

  @Test func diagnosticFromVariable() throws {
    let syntax = "let value: Int".asVariableDecl
    let variable = try #require(Variable.from(syntax).first)

    // Error on the whole variable
    let wholeDiag = variable.error("Must be mutable").build()
    #expect(wholeDiag.diagMessage.severity == .error)

    // Error on the binding keyword with fix-it
    let keywordDiag = variable
      .error("Expected 'var'", on: variable.bindingKeyword)
      .fix("Change to 'var'", replace: variable.bindingKeyword, with: .var)
      .build()

    #expect(keywordDiag.node.trimmedDescription == "let")
    #expect(keywordDiag.fixIts.count == 1)
  }

  @Test func diagnosticFromProperty() throws {
    let syntax = "public let value: Int".asVariableDecl
    let prop = try #require(Property.from(syntax).first)

    // Can use traits (accessLevel) and create diagnostics
    #expect(prop.accessLevel == .public)

    let diagnostic = prop
      .error("Properties must be private", on: prop.bindingKeyword)
      .build()

    #expect(diagnostic.diagMessage.severity == .error)
  }

  // MARK: - Builder Interpolation

  @Test func interpolatePropertyInSyntax() throws {
    let structSyntax = """
    struct Person {
      let name: String
      var age: Int
    }
    """.asStructDecl
    let properties = StructDecl(structSyntax).properties

    // Generate a CodingKeys enum using property names
    let codingKeys = try EnumDeclSyntax("enum CodingKeys: String, CodingKey") {
      for prop in properties {
        DeclSyntax("case \(prop)")
      }
    }

    let generated = codingKeys.trimmedDescription
    #expect(generated.contains("case name"))
    #expect(generated.contains("case age"))
  }

  @Test func interpolateEnumCaseInSyntax() throws {
    let enumSyntax = """
    enum Status {
      case active
      case inactive
      case pending
    }
    """.asEnumDecl
    let cases = EnumDecl(enumSyntax).cases

    // Generate is* computed properties
    let decls: [DeclSyntax] = try cases.map { enumCase in
      let upperName = enumCase.name.prefix(1).uppercased() + enumCase.name.dropFirst()
      return try DeclSyntax(
        VariableDeclSyntax("var is\(raw: upperName): Bool") {
          "if case .\(enumCase) = self { return true } else { return false }"
        })
    }

    #expect(decls.count == 3)
    #expect(decls[0].trimmedDescription.contains("isActive"))
    #expect(decls[0].trimmedDescription.contains(".active"))
  }

  @Test func interpolateAccessLevel() throws {
    let funcSyntax = "public func doSomething() {}".asFunctionDecl
    let fn = Function(funcSyntax)

    // Generate a wrapper function with same access level
    let wrapper = try FunctionDeclSyntax("\(fn.accessLevel)func wrapped_\(raw: fn.name)()") {
      "\(raw: fn.name)()"
    }

    let generated = wrapper.trimmedDescription
    #expect(generated.contains("public func wrapped_doSomething"))
  }

  @Test func interpolateParameter() {
    let funcSyntax = "func greet(to name: String, times count: Int) {}".asFunctionDecl
    let fn = Function(funcSyntax)

    // Forward parameters by their local names
    let params = fn.parameters
    #expect(params[0].label == "to")
    #expect(params[0].localName == "name")
    #expect(params[1].label == "times")
    #expect(params[1].localName == "count")

    // Generate a call expression using local names
    let call = ExprSyntax("original(\(raw: params.map(\.localName).joined(separator: ", ")))")
    #expect(call.trimmedDescription == "original(name, count)")
  }

  // MARK: - Typed DSL Builder

  @Test func typedDSLComputedProperty() throws {
    // Build a computed property using typed DSL
    let prop = try Var("isValid", type: .bool) {
      Return(.true)
    }

    let varDecl = try #require(prop.as(VariableDeclSyntax.self))
    let variable = try #require(Variable.from(varDecl).first)
    #expect(variable.name == "isValid")
    #expect(variable.type == "Bool")
    #expect(variable.mutable == false) // Getter-only computed property is not mutable

    // Check the body contains a return statement
    let body = varDecl.bindings.first?.accessorBlock?.accessors
    if case let .getter(items) = body {
      let returnStmt = items.first?.item.as(ReturnStmtSyntax.self)
      #expect(returnStmt?.expression?.description == "true")
    } else {
      Issue.record("Expected getter accessor block")
    }
  }

  @Test func typedDSLFunction() throws {
    let fn = try Func("greet", params: [("name", .string)], returns: .string) {
      Return(.expr("\"Hello, \" + name"))
    }

    let funcDecl = try #require(fn.as(FunctionDeclSyntax.self))
    let function = Function(funcDecl)
    #expect(function.name == "greet")
    #expect(function.returnType == "String")
    #expect(function.parameters.count == 1)
    #expect(function.parameters[0].label == "name")
    #expect(function.parameters[0].type == "String")

    // Check the body
    let returnStmt = funcDecl.body?.statements.first?.item.as(ReturnStmtSyntax.self)
    #expect(returnStmt?.expression?.description == "\"Hello, \" + name")
  }

  @Test func typedDSLStoredVar() throws {
    let stored = StoredVar("count", type: .int, value: .zero)

    let varDecl = try #require(stored.as(VariableDeclSyntax.self))
    let variable = try #require(Variable.from(varDecl).first)
    #expect(variable.name == "count")
    #expect(variable.type == "Int")

    // Check initializer value
    let initializer = varDecl.bindings.first?.initializer?.value
    #expect(initializer?.as(IntegerLiteralExprSyntax.self)?.literal.text == "0")
  }

  @Test func typedDSLLiterals() throws {
    // Test various literals using them in a function body
    let fn1 = try Func("test1") { Return(.true) }
    let fn2 = try Func("test2") { Return(.false) }
    let fn3 = try Func("test3") { Return(.nil) }
    let fn4 = try Func("test4") { Return(.int(42)) }
    let fn5 = try Func("test5") { Return(.string("hello")) }

    // Semantic checks on function structure
    #expect(fn1.as(FunctionDeclSyntax.self)?.name.text == "test1")
    #expect(fn2.as(FunctionDeclSyntax.self)?.name.text == "test2")
    #expect(fn3.as(FunctionDeclSyntax.self)?.name.text == "test3")
    #expect(fn4.as(FunctionDeclSyntax.self)?.name.text == "test4")
    #expect(fn5.as(FunctionDeclSyntax.self)?.name.text == "test5")

    /// Check return expressions
    func returnExpr(_ decl: DeclSyntax) -> ExprSyntax? {
      decl.as(FunctionDeclSyntax.self)?.body?.statements.first?.item.as(ReturnStmtSyntax.self)?.expression
    }

    #expect(returnExpr(fn1)?.as(BooleanLiteralExprSyntax.self)?.literal.text == "true")
    #expect(returnExpr(fn2)?.as(BooleanLiteralExprSyntax.self)?.literal.text == "false")
    #expect(returnExpr(fn3)?.as(NilLiteralExprSyntax.self) != nil)
    #expect(returnExpr(fn4)?.as(IntegerLiteralExprSyntax.self)?.literal.text == "42")
    #expect(returnExpr(fn5)?.as(StringLiteralExprSyntax.self)?.segments.description == "hello")
  }

  @Test func typedDSLTypeRef() {
    // Test type references
    #expect(TypeRef.bool.name == "Bool")
    #expect(TypeRef.array(of: .int).name == "[Int]")
    #expect(TypeRef.optional(.string).name == "String?")
    #expect(TypeRef.dict(key: .string, value: .int).name == "[String: Int]")
    #expect(TypeRef.result(success: .data).name == "Result<Data, Error>")
  }

  @Test func typedDSLIfElse() throws {
    let prop = try Var("status", type: .string) {
      try If("condition") {
        Return(.expr("\"yes\""))
      } else: {
        Return(.expr("\"no\""))
      }
    }

    let varDecl = try #require(prop.as(VariableDeclSyntax.self))
    let variable = try #require(Variable.from(varDecl).first)
    #expect(variable.name == "status")
    #expect(variable.type == "String")

    // Check the if expression structure
    let body = varDecl.bindings.first?.accessorBlock?.accessors
    if case let .getter(items) = body {
      let ifExpr = items.first?.item.as(IfExprSyntax.self)
      #expect(ifExpr != nil)
      #expect(ifExpr?.conditions.first?.condition.trimmedDescription == "condition")
      #expect(ifExpr?.elseBody != nil)
    } else {
      Issue.record("Expected getter accessor block")
    }
  }
}

// MARK: - Test Helpers

private extension String {
  var asVariableDecl: VariableDeclSyntax {
    Parser.parse(source: self).statements.first!.item.cast(VariableDeclSyntax.self)
  }

  var asFunctionDecl: FunctionDeclSyntax {
    Parser.parse(source: self).statements.first!.item.cast(FunctionDeclSyntax.self)
  }

  var asStructDecl: StructDeclSyntax {
    Parser.parse(source: self).statements.first!.item.cast(StructDeclSyntax.self)
  }

  var asInitializerDecl: InitializerDeclSyntax {
    let wrapped = "struct S { \(self) }"
    let structDecl = Parser.parse(source: wrapped).statements.first!.item.cast(StructDeclSyntax.self)
    return structDecl.memberBlock.members.first!.decl.cast(InitializerDeclSyntax.self)
  }

  var asEnumDecl: EnumDeclSyntax {
    Parser.parse(source: self).statements.first!.item.cast(EnumDeclSyntax.self)
  }
}
