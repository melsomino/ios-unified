//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class CloudApiFieldConverter<StructType> {
	public typealias FieldSetter = (StructType, AnyObject) -> Void
	public typealias FieldGetter = (StructType) -> AnyObject

	open let cloudName: String
	open let cloudTypeName: String
	open let fieldSetter: FieldSetter
	open let fieldGetter: FieldGetter


	public init(_ cloudName: String, _ cloudTypeName: String, _ fieldSetter: @escaping FieldSetter, _ fieldGetter: @escaping FieldGetter) {
		self.cloudName = cloudName
		self.cloudTypeName = cloudTypeName
		self.fieldSetter = fieldSetter
		self.fieldGetter = fieldGetter
	}
}
