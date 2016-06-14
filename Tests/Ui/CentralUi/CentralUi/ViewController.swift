//
//  ViewController.swift
//  CentralUi
//
//  Created by Власов М.Ю. on 14.06.16.
//  Copyright © 2016 melsomino. All rights reserved.
//

import UIKit

class Test {

	static func test<A: AnyObject>(a: A) {
		let c = A.self
		print(c)
	}
}


class ViewController: UIViewController {

	
	
	override func viewDidLoad() {
		super.viewDidLoad()

		Test.test(self)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


}

