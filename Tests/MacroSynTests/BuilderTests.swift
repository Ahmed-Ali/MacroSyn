//
//  BuilderTests.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 13/02/2026.
//

import Foundation
@testable import MacroSyn
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

///  Tests for the Writer/Builder DSL expansion.
///  Every test validates generated syntax output, not stored properties.
@Suite struct BuilderTests {
  // MARK: - Func (New API)

  @Test func funcBuilderSimple() throws {
    let decl = try Func("greet", Arg("name", type: String.self))
      .returns(.string) {
        Return(expr: "\"Hello, \" + name")
      }

    // Round-trip: parse generated syntax back through reader
    let fn = Function(decl.cast(FunctionDeclSyntax.self))
    #expect(fn.name == "greet")
    #expect(fn.returnType == "String")
    #expect(fn.parameters[0].label == "name")
    #expect(fn.parameters[0].type == "String")

    let body = try #require(decl.cast(FunctionDeclSyntax.self).body?.statements)
    #expect(body.first?.item.as(ReturnStmtSyntax.self)?.expression?.trimmedDescription == "\"Hello, \" + name")
  }

  @Test func funcBuilderVoidBody() throws {
    let decl = try Func("configure", Arg("name", type: String.self))
      .body {
        "self.name = name"
      }

    let fn = Function(decl.cast(FunctionDeclSyntax.self))
    #expect(fn.name == "configure")
    #expect(fn.returnType == nil)

    let body = try #require(decl.cast(FunctionDeclSyntax.self).body?.statements)
    #expect(try #require(body.first?.trimmedDescription.contains("self.name = name")))
  }

  @Test func funcBuilderAsyncThrows() throws {
    let decl = try Func("fetch", Arg("url", type: URL.self), async: true, throws: true)
      .returns(.data) {
        Return(expr: "try await URLSession.shared.data(from: url)")
      }

    let fn = Function(decl.cast(FunctionDeclSyntax.self))
    #expect(fn.isAsync == true)
    #expect(fn.isThrowing == true)
    #expect(fn.returnType == "Data")
    #expect(fn.parameters[0].label == "url")
    #expect(fn.parameters[0].type == "URL")
  }

  @Test func funcBuilderStaticAccess() throws {
    let decl = try Func("create", access: .public, static: true)
      .returns(.custom("Self")) {
        Return(expr: "Self()")
      }

    let funcDecl = decl.cast(FunctionDeclSyntax.self)
    let fn = Function(funcDecl)
    #expect(fn.accessLevel == .public)
    #expect(fn.returnType == "Self")

    // Verify static modifier is in the generated syntax
    let modifiers = funcDecl.modifiers.map(\.name.text)
    #expect(modifiers.contains("public"))
    #expect(modifiers.contains("static"))
  }

  @Test func funcBuilderMultipleArgs() throws {
    let decl = try Func(
      "move",
      Arg("from", name: "source", type: "URL"),
      Arg("to", name: "destination", type: "URL")).body {
      "FileManager.default.moveItem(at: source, to: destination)"
    }

    // Validate generated parameter syntax via reader round-trip
    let fn = Function(decl.cast(FunctionDeclSyntax.self))
    #expect(fn.parameters[0].label == "from")
    #expect(fn.parameters[0].secondName == "source")
    #expect(fn.parameters[0].type == "URL")
    #expect(fn.parameters[1].label == "to")
    #expect(fn.parameters[1].secondName == "destination")
    #expect(fn.parameters[1].type == "URL")
  }

  // MARK: - Init

  @Test func initBuilder() throws {
    let decl = try Init(Arg("name", type: String.self), Arg("age", type: Int.self)) {
      "self.name = name"
      "self.age = age"
    }

    let initDecl = decl.cast(InitializerDeclSyntax.self)
    let params = initDecl.signature.parameterClause.parameters
    #expect(params.count == 2)
    #expect(params.first?.firstName.text == "name")
    #expect(params.first?.type.trimmedDescription == "String")
    #expect(params.last?.firstName.text == "age")
    #expect(params.last?.type.trimmedDescription == "Int")
    #expect(initDecl.optionalMark == nil)

    let body = try #require(initDecl.body?.statements)
    #expect(body.count == 2)
    #expect(try #require(body.first?.trimmedDescription.contains("self.name = name")))
  }

  @Test func initBuilderFailable() throws {
    let decl = try Init(Arg("value", type: Int.self), failable: true) {
      try Guard("value > 0", otherwise: { Return(.nil) })
      "self.value = value"
    }

    let initDecl = decl.cast(InitializerDeclSyntax.self)
    #expect(initDecl.optionalMark?.text == "?")

    // Verify guard statement was generated in the body
    let body = try #require(initDecl.body?.statements)
    let guardStmt = try #require(body.first?.item.as(GuardStmtSyntax.self))
    #expect(guardStmt != nil)
    #expect(try #require(guardStmt?.conditions.trimmedDescription == "value > 0"))
  }

  @Test func initBuilderWithAccess() throws {
    let decl = try Init(access: .public) {
      "// empty"
    }

    let initDecl = decl.cast(InitializerDeclSyntax.self)
    let modifiers = initDecl.modifiers.map(\.name.text)
    #expect(modifiers.contains("public"))
    #expect(initDecl.signature.parameterClause.parameters.isEmpty)
  }

  // MARK: - Struct (thorough)

  @Test func structBuilder() throws {
    let decl = try Struct("User", access: .public, inherits: ["Codable", "Equatable"]) {
      StoredVar("name", type: .string)
      StoredVar("age", type: .int)
    }

    // Round-trip through reader to verify generated structure
    let structDecl = decl.cast(StructDeclSyntax.self)
    let reader = StructDecl(structDecl)
    #expect(reader.name == "User")
    #expect(reader.accessLevel == .public)
    #expect(reader.properties.count == 2)
    #expect(reader.properties[0].name == "name")
    #expect(reader.properties[0].type == "String")
    #expect(reader.properties[1].name == "age")
    #expect(reader.properties[1].type == "Int")

    // Verify inheritance clause in generated syntax
    let inherited = structDecl.inheritanceClause?.inheritedTypes.map(\.type.trimmedDescription)
    #expect(inherited == ["Codable", "Equatable"])
  }

  @Test func structBuilderNoInheritance() throws {
    let decl = try Struct("Point") {
      StoredVar("x", type: .double)
      StoredVar("y", type: .double)
    }

    let structDecl = decl.cast(StructDeclSyntax.self)
    #expect(structDecl.name.text == "Point")
    #expect(structDecl.inheritanceClause == nil)
    #expect(structDecl.memberBlock.members.count == 2)
  }

  // MARK: - Class

  @Test func classBuilder() throws {
    let decl = try Class("ViewModel", access: .public, inherits: ["ObservableObject"]) {
      StoredVar("title", type: .string, value: .emptyString)
    }

    let classDecl = decl.cast(ClassDeclSyntax.self)
    #expect(classDecl.name.text == "ViewModel")
    #expect(classDecl.modifiers.map(\.name.text).contains("public"))

    let inherited = classDecl.inheritanceClause?.inheritedTypes.map(\.type.trimmedDescription)
    #expect(inherited == ["ObservableObject"])

    // Verify the stored var member was generated
    let member = try #require(classDecl.memberBlock.members.first?.decl.as(VariableDeclSyntax.self))
    let variable = try #require(Variable.from(member).first)
    #expect(variable.name == "title")
    #expect(variable.type == "String")
  }

  // MARK: - Enum

  @Test func enumBuilder() throws {
    let decl = try Enum("Direction", inherits: ["String"]) {
      Case("north")
      Case("south")
      Case("east")
      Case("west")
    }

    let enumDecl = decl.cast(EnumDeclSyntax.self)
    #expect(enumDecl.name.text == "Direction")

    let inherited = enumDecl.inheritanceClause?.inheritedTypes.map(\.type.trimmedDescription)
    #expect(inherited == ["String"])

    // Verify all cases were generated
    let reader = EnumDecl(enumDecl)
    let caseNames = reader.cases.map(\.name)
    #expect(caseNames == ["north", "south", "east", "west"])
  }

  // MARK: - Extension

  @Test func extensionBuilder() throws {
    let decl = try Extension("User", conformingTo: ["CustomStringConvertible"]) {
      try Var("description", type: .string) {
        Return(expr: "name")
      }
    }

    let extDecl = decl.cast(ExtensionDeclSyntax.self)
    #expect(extDecl.extendedType.trimmedDescription == "User")

    let inherited = extDecl.inheritanceClause?.inheritedTypes.map(\.type.trimmedDescription)
    #expect(inherited == ["CustomStringConvertible"])

    // Verify the computed property member was generated
    let member = try #require(extDecl.memberBlock.members.first?.decl.as(VariableDeclSyntax.self))
    #expect(Variable.from(member).first?.name == "description")
  }

  @Test func extensionBuilderNoConformance() throws {
    let decl = try Extension("User") {
      try Func("validate").returns(.bool) {
        Return(.true)
      }
    }

    let extDecl = decl.cast(ExtensionDeclSyntax.self)
    #expect(extDecl.extendedType.trimmedDescription == "User")
    #expect(extDecl.inheritanceClause == nil)

    // Verify the function member was generated
    let member = try #require(extDecl.memberBlock.members.first?.decl.as(FunctionDeclSyntax.self))
    #expect(Function(member).name == "validate")
    #expect(Function(member).returnType == "Bool")
  }

  // MARK: - Case (enum)

  @Test func caseSimple() {
    let decl = Case("active")
    let caseDecl = decl.cast(EnumCaseDeclSyntax.self)
    #expect(caseDecl.elements.first?.name.text == "active")
    #expect(caseDecl.elements.first?.rawValue == nil)
    #expect(caseDecl.elements.first?.parameterClause == nil)
  }

  @Test func caseWithRawValue() {
    let decl = Case("north", rawValue: "\"N\"")
    let caseDecl = decl.cast(EnumCaseDeclSyntax.self)
    #expect(caseDecl.elements.first?.name.text == "north")
    #expect(caseDecl.elements.first?.rawValue?.value.trimmedDescription == "\"N\"")
  }

  @Test func caseWithAssociatedValues() throws {
    let decl = Case("error", args: (nil, "String"), ("code", "Int"))
    let caseDecl = decl.cast(EnumCaseDeclSyntax.self)
    #expect(caseDecl.elements.first?.name.text == "error")

    let params = try #require(caseDecl.elements.first?.parameterClause?.parameters)
    #expect(params.count == 2)
    #expect(params.first?.firstName == nil)
    #expect(params.first?.type.trimmedDescription == "String")
    #expect(params.last?.firstName?.text == "code")
    #expect(params.last?.type.trimmedDescription == "Int")
  }

  // MARK: - Switch

  @Test func switchBuilder() throws {
    let expr = try Switch("direction") {
      try SwitchCase("case .north:") {
        Return(expr: "\"up\"")
      }
      try SwitchCase("case .south:") {
        Return(expr: "\"down\"")
      }
      try SwitchCase("default:") {
        Return(expr: "\"unknown\"")
      }
    }

    let switchExpr = expr.cast(SwitchExprSyntax.self)
    #expect(switchExpr.subject.trimmedDescription == "direction")
    #expect(switchExpr.cases.count == 3)

    // Verify first case body contains return "up"
    let firstCase = try #require(switchExpr.cases.first?.as(SwitchCaseSyntax.self))
    let firstReturn = try #require(firstCase.statements.first?.item.as(ReturnStmtSyntax.self))
    #expect(firstReturn.expression?.trimmedDescription == "\"up\"")

    // Verify default case exists
    let lastCase = try #require(switchExpr.cases.last?.as(SwitchCaseSyntax.self))
    #expect(lastCase.label.trimmedDescription == "default:")
  }

  // MARK: - Do/Catch

  @Test func doCatchBuilder() throws {
    let stmt = try Do {
      "try riskyOperation()"
    } catch: {
      try Catch("let error as NetworkError") {
        "handleNetwork(error)"
      }
      try Catch {
        "print(error)"
      }
    }

    let doStmt = stmt.cast(DoStmtSyntax.self)

    // Verify do-body was generated
    #expect(try #require(doStmt.body.statements.first?.trimmedDescription.contains("try riskyOperation()")))

    // Verify catch clauses
    #expect(doStmt.catchClauses.count == 2)
    let firstCatch = try #require(doStmt.catchClauses.first)
    #expect(try #require(firstCatch.catchItems.first?.trimmedDescription.contains("let error as NetworkError")))
    #expect(try #require(firstCatch.body.statements.first?.trimmedDescription.contains("handleNetwork(error)")))

    // Verify bare catch
    let bareCatch = try #require(doStmt.catchClauses.last)
    #expect(bareCatch.catchItems.isEmpty)
    #expect(try #require(bareCatch.body.statements.first?.trimmedDescription.contains("print(error)")))
  }
}
