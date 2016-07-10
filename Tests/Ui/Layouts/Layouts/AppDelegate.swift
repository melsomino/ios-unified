//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified





struct Model1 {
	let a: String
	let b: Int
	let c: Bool
	let d: NSDate
}





@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CentralUiDependent, RepositoryDependent {

	var window: UIWindow?
	var dependency: DependencyResolver!


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		AppDelegate.testPerfomance()

		let m = Model1(a: "A", b: 12, c: true, d: NSDate())
		var b = UiBinding()
		let e = b.parse("a={a}, b={b}, c={c}, d={d}")
		b.setModel(m)
		print(b.evaluateExpression(e))



		dependency = DependencyContainer {
			container in
			container.createDefaultRepository()
			container.createDefaultCentralUi()
		}

		repository.devServerUrl = RepositoryDefaultDevServerUrl

		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window!.rootViewController = centralUi.rootController
		window!.makeKeyAndVisible()

		centralUi.addMenuItem("Layouts", title: "Layouts", icon: nil, action: .SetContent({ ViewController.create($0) }))
		centralUi.selectedMenuItem = centralUi.menuItemAtIndex(0)
		return true
	}


	static let perfomanceCount = 50000

	static func createTest(a: Int, _ b: String) -> Any {
		return Test(a, b)
	}

	static func testPerfomance() {
		measure("direct") {
			let test = createTest(1, "One")

			for _ in 0 ..< perfomanceCount {
				var a: String = ""
				var b: String = ""
				let o = test as! Test
				a = String(o.a)
				b = o.b
			}
		}
		measure("delegates") {
			let test = createTest(1, "One")
			let getA = aGetter()
			let getB = bGetter()

			for _ in 0 ..< perfomanceCount {
				var a: String = ""
				var b: String = ""
				a = getA(test)!
				b = getB(test)!
			}
		}

		measure("type info") {
			let test = createTest(1, "One")
			let typeInfo = (test as! SupportsTypeInfo).typeInfo
			let getA = typeInfo.requiredField("a").format
			let getB = typeInfo.requiredField("b").format

			for _ in 0 ..< perfomanceCount {
				var a: String = ""
				var b: String = ""
				a = getA(test)!
				b = getB(test)!
			}
		}


		measure("mirror") {
			let o = createTest(1, "One")
			let mirror = Mirror(reflecting: o)

			for _ in 0 ..< perfomanceCount {
				var a: String = ""
				var b: String = ""
				for (memberName, memberValue) in mirror.children {
					if memberName == "a" {
						a = String(memberValue as! Int)
					}
					else if memberName == "b" {
						b = memberValue as! String
					}
				}
			}
		}
	}

	static func aGetter() -> (Any) -> String? {
		return {
			String(($0 as! Test).a)
		}
	}
	static func bGetter() -> (Any) -> String? {
		return {
			($0 as! Test).b
		}
	}

	static func measure(title: String, test: () -> Void) {
		let start = NSDate()
		test()
		let time = NSDate().timeIntervalSinceDate(start) * 1000
		print("\(title): \(time)")
	}
}


struct TypeInfo {

	struct Field {
		let name: String
		let format: (Any) -> String?

		init(_ name: String, format: (Any) -> String?) {
			self.name = name
			self.format = format
		}

	}

	let fields: [Field]
	let fieldsByName: [String:Field]

	init(fields: [Field]) {
		self.fields = fields
		var fieldsByName = [String: Field]()
		for field in fields {
			fieldsByName[field.name] = field
		}
		self.fieldsByName = fieldsByName
	}

	func requiredField(name: String) -> Field {
		return fieldsByName[name]!
	}
}

protocol SupportsTypeInfo {
	var typeInfo: TypeInfo { get }
}

class Test {
	var a: Int
	var b: String
	init(_ a: Int, _ b: String) {
		self.a = a
		self.b = b
	}
}

extension Test: SupportsTypeInfo {
	var typeInfo: TypeInfo {
		return Test.typeInfo
	}

	static let typeInfo = TypeInfo(fields: [
		TypeInfo.Field("a", format: { String(($0 as! Test).a) }),
		TypeInfo.Field("b", format: { ($0 as! Test).b })
	])
}


