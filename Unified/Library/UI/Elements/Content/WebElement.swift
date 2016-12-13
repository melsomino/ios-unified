//
// Created by Michael Vlasov on 11.12.16.
//

import Foundation
import UIKit
import WebKit



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

	public var url: URL? {
		didSet {
			guard !URL.same(oldValue, url) else {
				return
			}
			guard let view = view as? WKWebView else {
				return
			}
			measuredHeight = nil
			if let url = url {
				view.load(URLRequest(url: url))
			}
			else {
				view.loadHTMLString("", baseURL: nil)
			}
		}
	}

	public var htmlBaseUrl: URL?

	public var html = "" {
		didSet {
			guard oldValue != html else {
				return
			}
			guard let view = view as? WKWebView else {
				return
			}
			measuredHeight = nil
			view.loadHTMLString(html, baseURL: htmlBaseUrl)
		}
	}


	public override required init() {
		super.init()
	}

	// MARK: - ContentElement


	public override func onViewCreated() {
		super.onViewCreated()
//		guard let view = view as? WKWebView else {
//			return
//		}
	}



	public override func initializeView() {
		super.initializeView()
		guard let view = view as? WKWebView else {
			return
		}
		measuredHeight = nil
		if let url = url {
			view.load(URLRequest(url: url))
		}
		else {
			view.loadHTMLString(html, baseURL: htmlBaseUrl)
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
		if let htmlBaseUrlBinding = definition.htmlBaseUrl {
			htmlBaseUrl = URL(string: htmlBaseUrlBinding.evaluate(values) ?? "")
		}
		if let urlBinding = definition.url {
			url = URL(string: urlBinding.evaluate(values) ?? "")
		}
		else if let htmlBinding = definition.html {
			html = htmlBinding.evaluate(values) ?? ""
		}
	}


	public override var visible: Bool {
		if hidden {
			return false
		}
		return url != nil || !html.isEmpty
	}


	public override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(width: (1, bounds.width), height: measuredHeight ?? initialHeight)
	}

	// MARK: - WKNavigationDelegate

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		webView.evaluateJavaScript("document.body.offsetHeight") {
			result, error in
			guard let height = result as? Double else {
				return
			}
			self.measuredHeight = CGFloat(height) / UIScreen.main.scale
			print(self.measuredHeight!)
			self.fragment?.layoutChanged(forElement: self)
		}
	}

	// MARK: - Internals

	var measuredHeight: CGFloat?
	private var delegateForwarder: WKDelegate?

}



public final class WebElementDefinition: ContentElementDefinition {
	public static let defaultInitialHeight = CGFloat(0)

	public var initialHeight = WebElementDefinition.defaultInitialHeight
	public var url: DynamicBindings.Expression?
	public var html: DynamicBindings.Expression?
	public var htmlBaseUrl: DynamicBindings.Expression?


	// MARK: - ElementDefinition


	public override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "initial-height":
				initialHeight = try context.getFloat(attribute)
			case "url":
				url = try context.getExpression(attribute)
			case "html":
				html = try context.getExpression(attribute)
			case "html-base-url":
				htmlBaseUrl = try context.getExpression(attribute)
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
