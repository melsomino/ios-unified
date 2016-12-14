//
// Created by Власов М.Ю. on 14.12.16.
//

import Foundation



public final class DeclarationTemplate {

	public static func from(declarations: [DeclarationElement]) -> [String: DeclarationTemplate] {
		var templates = [String: DeclarationTemplate]()
		for element in declarations {
			if element.name == "template" {
				for templateElement in element.children {
					templates[templateElement.name] = DeclarationTemplate(declaration: templateElement)
				}
			}
		}
		return templates
	}

	public static func apply(templates: [String: DeclarationTemplate], to elements: [DeclarationElement]) -> [DeclarationElement] {
		var resolved = elements
		while resolved.contains(where: { templates[$0.name] != nil }) {
			let unresolved = resolved
			resolved.removeAll(keepingCapacity: true)
			for element in unresolved {
				if let template = templates[element.name] {
					resolved.append(contentsOf: template.resolve(templateUsage: element))
				}
				else {
					resolved.append(element)
				}
			}
		}
		for i in resolved.indices {
			resolved[i].children = apply(templates: templates, to: resolved[i].children)
		}
		return resolved
	}


	// MARK: - Internals


	private var argIndexByName = ["": 0]
	private var argDefaultValues = [""]
	private var elementBuilders = [ElementBuilder]()

	init(declaration: DeclarationElement, nameAttribute: Int = 0) {
		for attribute in declaration.attributes(from: nameAttribute + 1) {
			argIndexByName[attribute.name] = argDefaultValues.count
			switch attribute.value {
				case .value(let value):
					argDefaultValues.append(value)
				default:
					argDefaultValues.append("")
			}
		}
		elementBuilders = declaration.children.map {
			ElementBuilder(declaration: $0, args: argIndexByName)
		}
	}



	private struct ElementBuilder {
		private var attributeBuilders = [AttributeBuilder]()
		private var childrenBuilders = [ElementBuilder]()

		init(declaration: DeclarationElement, args: [String: Int]) {
			attributeBuilders = declaration.attributes.map {
				AttributeBuilder(declaration: $0, args: args)
			}
			childrenBuilders = declaration.children.map {
				ElementBuilder(declaration: $0, args: args)
			}
		}



		func create(args: [String]) -> DeclarationElement {
			let elementAttributes = attributeBuilders.map({ $0.create(args: args) })
			let elementChildren = childrenBuilders.map({ $0.create(args: args) })
			return DeclarationElement(attributes: elementAttributes, children: elementChildren)
		}
	}



	private struct AttributeBuilder {
		private var nameBuilder = [StringPartBuilder]()
		private var valueBuilders = [[StringPartBuilder]]()

		init(declaration: DeclarationAttribute, args: [String: Int]) {
			nameBuilder = StringPartBuilder.from(string: declaration.name, args: args)
			switch declaration.value {
				case .value(let string):
					valueBuilders.append(StringPartBuilder.from(string: string, args: args))
				case .list(let list):
					for item in list {
						valueBuilders.append(StringPartBuilder.from(string: item, args: args))
					}
				default:
					break
			}
		}



		func create(args: [String]) -> DeclarationAttribute {
			let attributeName = StringPartBuilder.create(args: args, parts: nameBuilder)
			var attributeValues = valueBuilders.map({ StringPartBuilder.create(args: args, parts: $0) })
			var attributeValue: DeclarationValue
			switch attributeValues.count {
				case 0:
					attributeValue = .missing
				case 1:
					attributeValue = .value(attributeValues[0])
				default:
					attributeValue = .list(attributeValues)
			}
			return DeclarationAttribute(name: attributeName, value: attributeValue)
		}
	}



	private enum StringPartBuilder {
		case string(String)
		case arg(Int)



		static func from(string: String, args: [String: Int]) -> [StringPartBuilder] {
			var parts = [StringPartBuilder.string(string)]
			for (name, index) in args {
				replace(argName: "[\(name)]", argIndex: index, parts: &parts)
			}
			return parts
		}



		static func replace(argName: String, argIndex: Int, parts: inout [StringPartBuilder]) {
			var index = parts.count - 1
			while index >= 0 {
				if case .string(let string) = parts[index] {
					let ab = string.components(separatedBy: argName)
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



		static func create(args: [String], parts: [StringPartBuilder]) -> String {
			var string = ""
			for part in parts {
				switch part {
					case .string(let value):
						string += value
					case .arg(let index):
						string += args[index]
				}
			}
			return string
		}
	}


	private func getValue(element: DeclarationElement) -> String? {
		guard element.attributes.count > 1 else {
			return nil
		}
		let attribute = element.attributes[1]
		return attribute.value.isMissing ? attribute.name : nil
	}

	private func resolve(templateUsage: DeclarationElement) -> [DeclarationElement] {
		var resolved = [DeclarationElement]()
		var args = argDefaultValues
		var startAttribute = 1
		if let value = getValue(element: templateUsage) {
			args[0] = value
			startAttribute = 2
		}
		for attribute in templateUsage.attributes(from: startAttribute) {
			if let index = argIndexByName[attribute.name], case .value(let value) = attribute.value {
				args[index] = value
			}
		}
		for elementBuilder in elementBuilders {
			resolved.append(elementBuilder.create(args: args))
		}
		return resolved
	}



}
