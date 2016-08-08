//
// Created by Michael Vlasov on 05.08.16.
//

import Foundation




public class HtmlParser {


	public static func parse(html: String) {
		var s = html.characters.generate()
		while let c = s.next() {
			print(c.dynamicType)
		}
	}
}
