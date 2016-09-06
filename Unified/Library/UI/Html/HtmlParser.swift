//
// Created by Michael Vlasov on 05.08.16.
//

import Foundation





public struct HtmlParser {
	var text = ""

	public static func parse(html: String) -> String {
		var parser = HtmlParser()
		do {
			let doc = try HTMLDocument(string: html)
			if let body = doc.body {
				parser.parse_node(body)
			}
		} catch {

		}
		return parser.text
	}



	mutating func parse_node(node: XMLNode) {
		if let element = node as? XMLElement {
			let tag = element.tag?.lowercaseString ?? ""
			for child in element.childNodes(ofTypes: [.Element, .Text, .CDataSection]) {
				parse_node(child)
			}
			switch tag {
				case "br", "p", "div", "li":
					text += "\n"
				default:
					break
			}
		}
		else {
			text += node.stringValue
		}
	}


}
