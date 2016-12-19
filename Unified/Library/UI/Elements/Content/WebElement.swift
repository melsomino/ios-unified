//
// Created by Michael Vlasov on 11.12.16.
//

import Foundation
import UIKit
import WebKit



public enum WebElementSource {
	case unassigned
	case blank
	case url(URL)
	case html(String, URL?)



	public static func ==(_ a: WebElementSource, _ b: WebElementSource) -> Bool {
		switch a {
			case .unassigned:
				return b == .unassigned
			case .blank:
				return b == .blank
			case .url(let aUrl):
				if case .url(let bUrl) = b {
					return aUrl == bUrl
				}
				return false
			case .html(let aHtml, let aBaseUrl):
				if case .html(let bHtml, let bBaseUrl) = b {
					return aHtml == bHtml && URL.same(aBaseUrl, bBaseUrl)
				}
				return false
		}
	}
}



public final class WebElement: ContentElement {



	private class WKDelegate: NSObject, WKNavigationDelegate {
		unowned var owner: WebElement
		init(owner: WebElement) {
			self.owner = owner
		}



		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			owner.webView(webView, didFinish: navigation)
		}
	}



	public var initialHeight = WebElementDefinition.defaultInitialHeight

	public var source = WebElementSource.unassigned {
		didSet {
			if let view = view as? WKWebView {
				if oldValue == source {
				}
				else {
					load(view: view)
				}
			}
		}
	}

	public override required init() {
		super.init()
	}

	// MARK: - ContentElement


	private func load(view: WKWebView) {
		print("load: \(source)")
		switch source {
			case .unassigned:
				break
			case .blank:
				lastLoadNavigation = view.loadHTMLString("", baseURL: nil)
			case .url(let url):
				lastLoadNavigation = view.load(URLRequest(url: url))
			case .html(let html, let baseUrl):
				lastLoadNavigation = view.loadHTMLString(
					"<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=1.0;' />" +
						"<style>html { -webkit-text-size-adjust: none; }</style>" +
						"<body style='margin: 0; padding: 0'><div id=__web_element__>\(html)</div></body>", baseURL: baseUrl)
		}
	}



	public override func initializeView() {
		super.initializeView()
		if let view = view as? WKWebView {
			load(view: view)
		}
	}



	public override func createView() -> UIView {
		if delegateForwarder == nil {
			delegateForwarder = WKDelegate(owner: self)
		}
		let configuration = WKWebViewConfiguration()
		let view = WKWebView(frame: CGRect.zero, configuration: configuration)
		let scrollView: UIScrollView = view.scrollView
		scrollView.bounces = false
		view.navigationDelegate = delegateForwarder
		return view
	}


	// MARK: - FragmentElement


	public override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		guard let definition = definition as? WebElementDefinition else {
			return
		}
		let html = DynamicBindings.evaluate(expression: definition.html, values: values) ?? ""
		let url = URL(string: DynamicBindings.evaluate(expression: definition.url, values: values) ?? "")
		if !html.isEmpty {
			source = .html(html, url)
		}
		else if let url = url {
			source = .url(url)
		}
		else {
			source = .blank
		}
	}


	public override var visible: Bool {
		if hidden {
			return false
		}
		return !(source == .blank)
	}

	public override var frame: CGRect {
		didSet {
			if let view = view as? WKWebView, lastLoadNavigation == nil && layoutValue(forKey: "measuredHeight") as CGFloat? == nil {
				OperationQueue.main.addOperation {
					self.evalHeight(view: view)
				}
			}
		}
	}

	public override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		if let height = layoutValue(forKey: "measuredHeight") as CGFloat? {
			print("measureContent: \(height)")
			return SizeMeasure(width: (1, bounds.width), height: height)
		}
		return SizeMeasure(width: (1, bounds.width), height: initialHeight)
	}

	// MARK: - WKNavigationDelegate

	func evalHeight(view: WKWebView) {
		let js = "var __web_element__ = document.getElementById('__web_element__');" +
		"__web_element__ ? __web_element__.offsetHeight : document.body.offsetHeight;"

		view.evaluateJavaScript(js) {
			result, error in
			guard let height = result as? Double else {
				print("height eval error: \(error)")
				return
			}
			let measuredHeight = CGFloat(height)
			let oldMeasured = self.layoutValue(forKey: "measuredHeight") as CGFloat?
			if oldMeasured == nil || oldMeasured! != measuredHeight {
				print("measured: \(measuredHeight)")
				self.setLayout(value: measuredHeight, forKey: "measuredHeight")
				self.fragment?.layoutChanged(forElement: self)
			}
		}
	}



	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		guard lastLoadNavigation != nil && navigation == lastLoadNavigation! else {
			return
		}
		lastLoadNavigation = nil
		evalHeight(view: webView)
	}

	// MARK: - Internals

	private var lastLoadNavigation: WKNavigation?
	private var delegateForwarder: WKDelegate?

}



public final class WebElementDefinition: ContentElementDefinition {
	public static let defaultInitialHeight = CGFloat(0)

	public var initialHeight = WebElementDefinition.defaultInitialHeight
	public var url: DynamicBindings.Expression?
	public var html: DynamicBindings.Expression?


	// MARK: - ElementDefinition


	public override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "initial-height":
				initialHeight = try context.getFloat(attribute)
			case "url":
				url = try context.getExpression(attribute)
			case "html":
				html = try context.getExpression(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}



	public override func createElement() -> FragmentElement {
		return WebElement()
	}



	public override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		guard let element = element as? WebElement else {
			return
		}
		element.initialHeight = initialHeight
	}


}
