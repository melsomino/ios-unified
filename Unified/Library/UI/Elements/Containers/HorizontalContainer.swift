//
// Created by Michael Vlasov on 27.07.16.
//

import Foundation





open class HorizontalContainer: MultipleElementContainer {
	var spacing = CGFloat(0)

	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		var measure = Horizontal_layout(container: self, bounds: bounds)
		measure.measure()
		return measure.size
	}



	open override func layoutContent(inBounds bounds: CGRect) {
		var measure = Horizontal_layout(container: self, bounds: bounds.size)
		measure.measure()
		measure.layout(with_origin: bounds.origin)
	}
}





class HorizontalContainerDefinition: FragmentElementDefinition {

	var spacing = CGFloat(0)

	override func createElement() -> FragmentElement {
		return HorizontalContainer()
	}



	override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let horizontal = element as! HorizontalContainer
		horizontal.children = children
		horizontal.spacing = spacing
	}



	override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "spacing":
				spacing = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}

}





//  Horizontal_measure
//
//  Incorporates measurements and layouting logic of horizontal container
//





private struct Horizontal_layout {





	fileprivate struct Element_layout {
		let element: FragmentElement
		var size = SizeMeasure.zero
		var bounds_width = CGFloat(0)

		init(element: FragmentElement) {
			self.element = element
		}



		mutating func measure(in_bounds bounds: CGSize) -> SizeMeasure {
			size = element.measure(inBounds: bounds)
			return size
		}



		mutating func set_bounds_width(fill_width_ratio fill: CGFloat, non_fill_width_ratio non_fill: CGFloat) {
			bounds_width = size.width.max * (element.horizontalAlignment == .fill ? fill : non_fill)
		}

		var fill: Bool {
			return element.horizontalAlignment == .fill
		}

		var fixed: Bool {
			return size.width.min >= size.width.max
		}

		var flexible: Bool {
			return size.width.max > size.width.min
		}
	}





	let container: HorizontalContainer
	let bounds: CGSize
	let total_spacing: CGFloat
	var children = [Element_layout]()
	var size = SizeMeasure.zero
	var has_fill = false

	init(container: HorizontalContainer, bounds: CGSize) {
		self.container = container
		self.bounds = bounds
		for element in container.children {
			if element.visible {
				if element.horizontalAlignment == .fill {
					has_fill = true
				}
				children.append(Element_layout(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}



	func width_of(_ predicate: (Element_layout) -> Bool) -> (min:CGFloat, max:CGFloat) {
		var width = (min: CGFloat(0), max: (CGFloat(0)))
		for child in children {
			if predicate(child) {
				width.min += child.size.width.min
				width.max += child.size.width.max
			}
		}
		return width
	}



	mutating func measure() {
		pre_measure()
		if size.width.max <= bounds.width {
			set_children_bounds_width_when_max_inside_bounds()
		}
		else if size.width.min >= bounds.width {
			remeasure_when_min_exceed_bounds()
		}
		else if size.width.max > bounds.width {
			remeasure_when_max_exceed_bounds()
		}
	}



	mutating func pre_measure() {
		let max_child_bounds = CGSize(width: bounds.width - total_spacing, height: bounds.height)
		size = SizeMeasure(width: total_spacing, height: 0)
		measure_children {
			return $0.measure(in_bounds: max_child_bounds)
		}
	}



	mutating func set_children_bounds_width(fill_width_ratio fill: CGFloat, non_fill_width_ratio non_fill: CGFloat) {
		for i in 0 ..< children.count {
			children[i].set_bounds_width(fill_width_ratio: fill, non_fill_width_ratio: non_fill)
		}
	}



	mutating func set_children_bounds_width_when_max_inside_bounds() {
		if has_fill {
			var fill_space = bounds.width - total_spacing
			var fill_width = CGFloat(0)
			for child in children {
				if child.element.horizontalAlignment == .fill {
					fill_width += child.size.width.max
				}
				else {
					fill_space -= child.size.width.max
				}
			}
			set_children_bounds_width(fill_width_ratio: fill_space / fill_width, non_fill_width_ratio: 1)
			size.width.max = bounds.width
		}
		else if size.width.max > total_spacing {
			set_children_bounds_width(fill_width_ratio: 1, non_fill_width_ratio: (bounds.width - total_spacing) / (size.width.max - total_spacing))
		}
	}



	mutating func remeasure_when_min_exceed_bounds() {
		if has_fill {
			let not_fill_width = width_of({ !$0.fill }).min
			let fill_width = width_of({ $0.fill }).max
			let fill_space = bounds.width - not_fill_width - total_spacing
			if fill_space > 0 {
				let fill_with_ratio = fill_space / fill_width
				measure_children {
					$0.bounds_width = $0.element.horizontalAlignment == .fill ? $0.size.width.max * fill_with_ratio : $0.size.width.min
					return $0.measure(in_bounds: CGSize(width: $0.bounds_width, height: 0))
				}
				return
			}
		}
		let with_ratio = bounds.width / size.width.min
		measure_children {
			$0.bounds_width = $0.size.width.min * with_ratio
			return $0.measure(in_bounds: CGSize(width: $0.bounds_width, height: 0))
		}
	}



	mutating func remeasure_when_max_exceed_bounds() {
		let width_ratio = (bounds.width - size.width.min) / (size.width.max - size.width.min)
		measure_children {
			let width = $0.size.width
			if width.max > width.min {
				$0.bounds_width = width.min + (width.max - width.min) * width_ratio
				return $0.measure(in_bounds: CGSize(width: $0.bounds_width, height: 0))
			}
			else {
				$0.bounds_width = width.min
			}
			return $0.size
		}
	}



	mutating func measure_children(_ measure_child: (_ child:inout Element_layout) -> SizeMeasure) {
		size = SizeMeasure(width: total_spacing, height: 0)
		for i in 0 ..< children.count {
			let child = measure_child(&children[i])
			size.width.min += child.width.min
			size.width.max += child.width.max
			size.height = max(size.height, child.height)
		}
	}



	mutating func layout(with_origin origin: CGPoint) {
		let y = origin.y
		var x = origin.x
		for child in children {
			let child_bounds = CGRect(x: x, y: y, width: child.bounds_width, height: size.height)
			var child_size = child.size.maxSize
			if child_size.width > child_bounds.width {
				child_size.width = child_bounds.width
			}
			if child_size.height > child_bounds.height {
				child_size.height = child_bounds.height
			}
			child.element.layout(inBounds: child_bounds, usingMeasured: child_size)
			x += child_bounds.width + container.spacing
		}
	}
}


