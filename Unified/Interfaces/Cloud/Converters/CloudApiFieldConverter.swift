//
// Created by Власов М.Ю. on 12.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class CloudApiFieldConverter<StructType> {
	public typealias FieldSetter = (StructType, AnyObject) -> Void
	public typealias FieldGetter = (StructType) -> AnyObject

	public let cloudName: String
	public let cloudTypeName: String
	public let fieldSetter: FieldSetter
	public let fieldGetter: FieldGetter


	public init(_ cloudName: String, _ cloudTypeName: String, _ fieldSetter: FieldSetter, _ fieldGetter: FieldGetter) {
		self.cloudName = cloudName
		self.cloudTypeName = cloudTypeName
		self.fieldSetter = fieldSetter
		self.fieldGetter = fieldGetter
	}
}
