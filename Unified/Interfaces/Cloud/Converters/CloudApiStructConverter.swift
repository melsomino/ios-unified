//
// Created by Власов М.Ю. on 12.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class CloudApiStructConverter<StructType> {

	public typealias ObjectFactory = () -> StructType

	public let objectFactory: ObjectFactory
	public let fields: [CloudApiFieldConverter<StructType>]

	private var fieldByCloudName = [String: CloudApiFieldConverter < StructType>]()





	public init(_ objectFactory: ObjectFactory, _ fields: [CloudApiFieldConverter<StructType>]) {
		self.objectFactory = objectFactory
		self.fields = fields
		for field in fields {
			fieldByCloudName[field.cloudName] = field
		}
	}





	public func objectFromJsonRecord(source: AnyObject) -> StructType? {
		guard let sourceObject = source as? [String:AnyObject] else {
			return nil
		}
		guard let data = sourceObject["d"] as? [AnyObject] else {
			return nil
		}
		return objectFromJsonRecordData(data, createFieldBindings(sourceObject))
	}





	public func listFromJsonRecordset(source: AnyObject) -> [StructType] {
		var objects = [StructType]()
		if let sourceObject = source as? [String:AnyObject] {
			if let table = sourceObject["d"] as? [AnyObject] {
				let bindings = createFieldBindings(sourceObject)
				for record in table {
					objects.append(objectFromJsonRecordData(record as! [AnyObject], bindings))
				}
			}
		}
		return objects
	}





	public func objectFromJsonObject(source: AnyObject) -> StructType? {
		guard let sourceObject = source as? [String:AnyObject] else {
			return nil
		}
		let object = objectFactory()
		for (name, value) in sourceObject {
			if let field = fieldByCloudName[name] {
				field.fieldSetter(object, value)
			}
		}
		return object
	}





	public func listFromJsonParameterRecordset(source: AnyObject) -> StructType? {
		let object = objectFactory()
		let values = CloudApiParameterValue.converter.listFromJsonRecordset(source)
		for value in values {
			if let field = fieldByCloudName[value.parameter ?? ""] {
				field.fieldSetter(object, value.value ?? NSNull())
			}
		}
		return object
	}





	public func jsonRecordFromObject(source: StructType?) -> AnyObject {
		guard source != nil else {
			return NSNull()
		}
		var record = [String: AnyObject]()
		record["s"] = jsonSchema()
		record["d"] = jsonRecordDataFromObject(source!)
		record["_type"] = "record"
		return record
	}





	public func jsonRecordsetFromList(list: [StructType]) -> AnyObject {
		var data = [AnyObject]()
		for object in list {
			data.append(jsonRecordDataFromObject(object))
		}
		var recordset = [String: AnyObject]()
		recordset["s"] = jsonSchema()
		recordset["d"] = data
		recordset["_type"] = "table"
		return recordset
	}





	public func jsonObjectFromObject(source: StructType?) -> AnyObject {
		guard source != nil else {
			return NSNull()
		}
		var result = [String: AnyObject]()
		for field in fields {
			result[field.cloudName] = field.fieldGetter(source!)
		}
		return result
	}


	public func objectFromJsonStringRecord(source: AnyObject) -> StructType? {
		return objectFromJsonRecord(decodeJsonString(source))
	}





	public func listFromJsonStringRecordset(source: AnyObject) -> [StructType] {
		return listFromJsonRecordset(decodeJsonString(source))
	}





	public func objectFromJsonStringObject(source: AnyObject) -> StructType? {
		return objectFromJsonObject(decodeJsonString(source))
	}





	public func listFromJsonStringParameterRecordset(source: AnyObject) -> StructType? {
		return listFromJsonParameterRecordset(decodeJsonString(source))
	}




	public func jsonStringRecordFromObject(source: StructType?) -> AnyObject {
		return encodeJsonString(jsonRecordFromObject(source))
	}





	public func jsonStringRecordsetFromList(list: [StructType]) -> AnyObject {
		return encodeJsonString(jsonRecordsetFromList(list))
	}





	public func jsonStringObjectFromObject(source: StructType?) -> AnyObject {
		return encodeJsonString(jsonObjectFromObject(source))
	}


	// MARK: - Internals


	typealias FieldBinding = (index:Int, field:CloudApiFieldConverter<StructType>)


	private func createFieldBindings(source: [String:AnyObject]) -> [FieldBinding] {
		var bindings = [FieldBinding]()
		if let schemaArray = source["s"] as? [AnyObject] {
			var index = 0
			for schemaItem in schemaArray {
				if let fieldSchema = schemaItem as? [String:AnyObject] {
					if let field = fieldByCloudName[fieldSchema["n"] as? String ?? ""] {
						bindings.append((index, field))
					}
				}
				index += 1
			}
		}
		return bindings
	}





	private func jsonSchema() -> [AnyObject] {
		var schema = [AnyObject]()
		for field in fields {
			var fieldSchema = [String: AnyObject]()
			fieldSchema["n"] = field.cloudName
			fieldSchema["t"] = field.cloudTypeName
			schema.append(fieldSchema)
		}
		return schema
	}





	private func objectFromJsonRecordData(source: [AnyObject], _ bindings: [FieldBinding]) -> StructType {
		let object = objectFactory()
		for binding in bindings {
			binding.field.fieldSetter(object, source[binding.index])
		}
		return object
	}




	private func jsonRecordDataFromObject(object: StructType) -> [AnyObject] {
		var data = [AnyObject]()
		for field in fields {
			data.append(field.fieldGetter(object) ?? NSNull())
		}
		return data
	}




	private func decodeJsonString(source: AnyObject) -> AnyObject {
		guard let string = source as? String else {
			return source
		}
		let encoded = string.dataUsingEncoding(NSUTF8StringEncoding)!
		do {
			return try NSJSONSerialization.JSONObjectWithData(encoded, options: [])
		}
		catch let error as NSError {
			print("decodeJsonError: \(error)")
			print("Invalid JSON:\n--------------------------------------\n\(string)\n--------------------------------------\n")
		}
		catch {
		}
		return NSNull()
	}




	private func encodeJsonString(source: AnyObject) -> AnyObject {
		guard source is [AnyObject] || source is [String:AnyObject] else {
			return source
		}
		let encoded = try! NSJSONSerialization.dataWithJSONObject(source, options: [])
		return String(data: encoded, encoding: NSUTF8StringEncoding)!
	}
}
