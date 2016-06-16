//
//  ViewController.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Melsomino. All rights reserved.
//

import UIKit
import Unified

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		let markup = [
			"vertical padding=(12 8) spacing=8",
			"    horizontal spacing=8",
			"        view #icon",
			"        vertical",
			"            label #text",
			"            label #details",
			"    label #warning font=('Helvetica Neue' 14) color=red",
			"    label #footer font=13 color=aaa",
		]
		let token = try! MarkupToken.parse(markup)
		print(token)
	}

}

