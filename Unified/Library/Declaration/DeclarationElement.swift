//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



public struct DeclarationAttribute: CustomStringConvertible {
	public var name: String
	public var value: DeclarationValue

	// MARK: - CustomStringConvertible

	public var description: String {
		switch value {
			case .missing:
				return "\(name)"
			default:
				return "'\(name)'=\(value)"
		}
	}

}



public struct DeclarationElement {
	public var attributes: [DeclarationAttribute]
	public var children: [DeclarationElement]


	public var name: String {
		return attributes[0].name
	}


	public var value: String? {
		return attributes.count > 1 ? attributes[1].name : nil
	}

	public static func load(_ path: String) throws -> [DeclarationElement] {
		let string = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
		return try parse(string)
	}



	public func attributes(from start: Int) -> ArraySlice<DeclarationAttribute> {
		return attributes[start ..< attributes.count]
	}

	public var skipName: ArraySlice<DeclarationAttribute> {
		return attributes[1 ..< attributes.count]
	}

	public func find(attribute: String) -> DeclarationAttribute? {
		return attributes.find({ $0.name == attribute })
	}



	public func find(child: String) -> DeclarationElement? {
		return children.find({ $0.name == child })
	}



	public static func parse(_ source: String) throws -> [DeclarationElement] {
		let scanner = Scanner(source: source, passWhitespaces: false)
		return try parseElements(scanner, elementIndent: 0)
	}



	// MARK: - Internals


	static func parseElement(_ scanner: Scanner, elementIndent: Int) throws -> DeclarationElement? {
		guard !scanner.isAtEnd else {
			return nil
		}

		scanner.passEmptyAndCommentLines()

		guard scanner.passDeclarationIndent(elementIndent) else {
			return nil
		}

		let attributes = try scanner.parseDeclarationAttributes(elementIndent)
		let children = try parseElements(scanner, elementIndent: elementIndent + 1)

		return DeclarationElement(attributes: attributes, children: children)
	}



	static func parseElements(_ scanner: Scanner, elementIndent: Int) throws -> [DeclarationElement] {
		var elements = [DeclarationElement]()
		while let element = try parseElement(scanner, elementIndent: elementIndent) {
			elements.append(element)
		}
		return elements
	}

}



public final class DeclarationTemplate {

	private var argIndexByName = ["": 0]
	private var argDefaultValues = [""]
	private var elements = [ElementTemplate]()

	init(declaration: DeclarationElement, nameAttribute: Int = 0) {
		for attribute in declaration.attributes(from: nameAttribute + 1) {
			argIndexByName[attribute.name] = argDefaultValues.count
			switch attribute.value {
				case .string(let value):
					argDefaultValues.append(value)
				default:
					argDefaultValues.append("")
			}
		}
		elements = declaration.children.map {
			ElementTemplate(declaration: $0, args: argIndexByName)
		}
	}



	private class ElementTemplate {
		private var attributes = [AttributeTemplate]()
		private var children = [ElementTemplate]()

		init(declaration: DeclarationElement, args: [String:Int]) {
			attributes = declaration.attributes.map {
				AttributeTemplate(declaration: $0, args: args)
			}
			children = declaration.children.map {
				ElementTemplate(declaration: $0, args: args)
			}
		}



		func resolve(args: [String]) -> DeclarationElement {
			var elementAttributes = attributes.map({ $0.resolve(args: args) })
			var elementChildren = children.map({ $0.resolve(args: args) })
			var element = DeclarationElement(attributes: elementAttributes, children: elementChildren)
		}
	}



	private class AttributeTemplate {
		private var name = [StringTemplate]()
		private var values = [[StringTemplate]]()

		init(declaration: DeclarationAttribute, args: [String:Int]) {
			name = StringTemplate.from(string: declaration.name, args: args)
			switch declaration.value {
				case .value(let string):
					values.append(StringTemplate.from(string: string, args: args))
				case .list(let values):
					for value in values {
						if case .string(let string) = value {
							values.append(StringTemplate.from(string: value, args: args))
						}
					}
			}
		}

		func resolve(args: [String]) -> DeclarationAttribute {
			let attributeName = StringTemplate.resolve(args: args, parts: name)
			var attributeValues = values.map({ StringTemplate.resolve(args: args, parts: $0) })
			var attributeValue: DeclarationValue
			switch attributeValues.count {
				case 0:
					attributeValue = .missing
				case 1:
					attributeValue = .value(attributeValues[0])
				default:
					attributeValue = .list(attributeValues.map({ .string(0) }))
			}
			return DeclarationAttribute(name: attributeName, value: attributeValue)
		}
	}



	private enum StringTemplate {
		case string(String)
		case arg(Int)


		static func from(string: String, args: [String:Int]) -> [StringTemplate] {
			var parts = [StringTemplate.string(string)]
			for (name, index) in args {
				replace(argName: "[\(name)]", argIndex: index, parts: &parts)
			}
			return parts
		}

		static func replace(argName: String, argIndex: Int, parts: inout [StringTemplate]) {
			var index = parts.count - 1
			while index >= 0 {
				if case .string(let string) = parts[index] {
					let ab = string.components(separatedBy: argName)
					print(ab)
					if ab.count > 1 {
						parts.remove(at: index)
						var i = index
						var first = true
						for s in ab {
							if first {
								first = false
							}
							else {
								parts.insert(.arg(argIndex), at: i)
								i += 1
							}
							if !s.isEmpty {
								parts.insert(.string(s), at: i)
								i += 1
							}
						}
					}
				}
				index -= 1
			}
		}

		static func resolve(args: [String], parts: [StringTemplate]) -> String? {
			guard parts.count > 0 else {
				return nil
			}
			var resolved = ""
			for part in parts {
				switch self {
					case .string(let value):
						resolved += value
					case .arg(let index):
						resolved += args[index]
				}
			}
			return resolved
		}
	}



	private func resolve(element: DeclarationElement) -> [DeclarationElement] {
		var resolved = [DeclarationElement]()
		var args = argDefaultValues
		var startAttribute = 1
		if let value = element.value {
			args[0] = value
			startAttribute = 2
		}
		for attribute in element.attributes(from: startAttribute) {
			if let index = argIndexByName[attribute.name], case .string(let value) = attribute.value {
				args[index] = value
			}
		}
		for child in children {
			resolved.append(child.resolve(args: args))
		}
		return resolved
	}



	public static func apply(templates: [String: DeclarationTemplate], to elements: [DeclarationElement]) -> [DeclarationElement] {
		var resolved = elements
		while resolved.contains(where: { templates[$0.name] != 0 }) {
			let unresolved = resolved
			resolved.removeAll(keepingCapacity: true)
			for element in unresolved {
				if let template = templates[element.name] {
					resolved.append(contentsOf: template.resolve(element: element))
				}
				else {
					resolved.append(element)
				}
			}
		}
		for element in resolved {
			element.children = apply(templates: templates, to: element.children)
		}
		return resolved
	}



	public static func templates(from declarations: [DeclarationElement]) -> [String: DeclarationTemplate] {
		var templates = [String: DeclarationElement]()
		for element in declarations {
			if element.name == "template" {
				for templateElement in element.children {
					templates[templateElement.name] = DeclarationTemplate(declaration: templateElement)
				}
			}
		}
		return templates
	}
}



// MARK: - Scanner extension



extension Scanner {

	func passEmptyAndCommentLines() {
		while !isAtEnd {
			let saveLocation = scanLocation
			passWhitespaces()
			if pass("#", passWhitespaces: false) {
				let _ = passUntilEndOrOneOf(CharacterSet.newlines, passWhitespaces: false)
			}
			if isAtEnd {
				return
			}
			if passCharacters(CharacterSet.newlines, passWhitespaces: false) == nil {
				scanLocation = saveLocation
				return
			}
		}
	}



	func passDeclarationIndent(_ expected: Int) -> Bool {
		var indent = 0
		let saveLocation = scanLocation
		if pass("\t", passWhitespaces: false) {
			indent += 1
			while pass("\t", passWhitespaces: false) {
				indent += 1
			}
		}
		else if pass("    ", passWhitespaces: false) {
			indent += 1
			while pass("    ", passWhitespaces: false) {
				indent += 1
			}
		}
		if indent != expected {
			scanLocation = saveLocation
		}
		return indent == expected
	}



	func parseDeclarationAttributes(_ elementIndent: Int) throws -> [DeclarationAttribute] {
		var attributes = [DeclarationAttribute]()
		while !isAtEnd {
			if passCharacters(CharacterSet.newlines) != nil {
				let saveLocation = scanLocation
				if !(passDeclarationIndent(elementIndent + 1) && pass("~", passWhitespaces: true)) {
					scanLocation = saveLocation
					break
				}
			}
			let name = try expectName(passWhitespaces: true)
			var value = DeclarationValue.missing
			if pass("=", passWhitespaces: true) {
				value = try passAttributeValue()
			}
			attributes.append(DeclarationAttribute(name: name, value: value))
		}
		return attributes
	}



	func passAttributeValue() throws -> DeclarationValue {
		if pass("(", passWhitespaces: true) {
			var values = [DeclarationValue]()
			while !pass(")", passWhitespaces: true) {
				guard let value = try passNameOrValue() else {
					throw ParseError("Invalid value list", self)
				}
				values.append(.value(value))
			}
			return .list(values)
		}
		return try .value(passNameOrValue()!)
	}



	func passNameOrValue() throws -> String? {
		if pass("'", passWhitespaces: false) {
			let value = passUntil("'") ?? ""
			try expect("'", passWhitespaces: true)
			return value
		}
		if pass("\"", passWhitespaces: false) {
			let value = passUntil("\"") ?? ""
			try expect("\"", passWhitespaces: true)
			return value
		}
		return passUntilEndOrOneOf(nameOrValueTerminator, passWhitespaces: true)
	}



	func expectName(passWhitespaces: Bool) throws -> String {
		guard let passed = try passNameOrValue() else {
			throw ParseError("name expected", self)
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return passed
	}


}



private let nameOrValueTerminator = CharacterSet.union(CharacterSet.whitespacesAndNewlines, CharacterSet(charactersIn: "=()'~"))
private let nameCharacters = CharacterSet.union(CharacterSet.alphanumerics, CharacterSet(charactersIn: "-."))
