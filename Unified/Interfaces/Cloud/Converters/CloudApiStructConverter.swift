//
//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class CloudApiStructConverter<StructType> {

	public typealias ObjectFactory = () -> StructType

	open let objectFactory: ObjectFactory
	open let fields: [CloudApiFieldConverter<StructType>]

	fileprivate var fieldByCloudName = [String: CloudApiFieldConverter < StructType>]()





	public init(_ objectFactory: @escaping ObjectFactory, _ fields: [CloudApiFieldConverter<StructType>]) {
		self.objectFactory = objectFactory
		self.fields = fields
		for field in fields {
			fieldByCloudName[field.cloudName] = field
		}
	}





	open func objectFromJsonRecord(_ source: AnyObject) -> StructType? {
		guard let sourceObject = source as? [String:AnyObject] else {
			return nil
		}
		guard let data = sourceObject["d"] as? [AnyObject] else {
			return nil
		}
		if data.count == 0 {
			return nil
		}
		return objectFromJsonRecordData(data, createFieldBindings(sourceObject))
	}





	open func listFromJsonRecordset(_ source: AnyObject) -> [StructType] {
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





	open func listFromJsonArray(_ source: AnyObject) -> [StructType] {
		var objects = [StructType]()
		guard let sourceArray = source as? [AnyObject] else {
			return objects
		}
		for value in sourceArray {
			if let object = objectFromJsonObject(value) {
				objects.append(object)
			}
		}
		return objects
	}





	open func objectFromJsonObject(_ source: AnyObject) -> StructType? {
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





	open func listFromJsonParameterRecordset(_ source: AnyObject) -> StructType? {
		let object = objectFactory()
		let values = CloudApiParameterValue.converter.listFromJsonRecordset(source)
		for value in values {
			if let field = fieldByCloudName[value.parameter ?? ""] {
				field.fieldSetter(object, value.value ?? NSNull())
			}
		}
		return object
	}





	open func jsonRecordFromObject(_ source: StructType?) -> AnyObject {
		guard source != nil else {
			return NSNull()
		}
		var record = [String: AnyObject]()
		record["s"] = jsonSchema() as AnyObject?
		record["d"] = jsonRecordDataFromObject(source!) as AnyObject?
		record["_type"] = "record" as AnyObject?
		return record as AnyObject
	}





	open func jsonRecordsetFromList(_ list: [StructType]) -> AnyObject {
		var data = [AnyObject]()
		for object in list {
			data.append(jsonRecordDataFromObject(object) as AnyObject)
		}
		var recordset = [String: AnyObject]()
		recordset["s"] = jsonSchema() as AnyObject?
		recordset["d"] = data as AnyObject?
		recordset["_type"] = "table" as AnyObject?
		return recordset as AnyObject
	}





	open func jsonArrayFromList(_ list: [StructType]) -> [AnyObject] {
		var array = [AnyObject]()
		for object in list {
			array.append(jsonObjectFromObject(object))
		}
		return array
	}





	open func jsonObjectFromObject(_ source: StructType?) -> AnyObject {
		guard source != nil else {
			return NSNull()
		}
		var result = [String: AnyObject]()
		for field in fields {
			result[field.cloudName] = field.fieldGetter(source!)
		}
		return result as AnyObject
	}


	open func objectFromJsonStringRecord(_ source: AnyObject) -> StructType? {
		return objectFromJsonRecord(decodeJsonString(source))
	}





	open func listFromJsonStringRecordset(_ source: AnyObject) -> [StructType] {
		return listFromJsonRecordset(decodeJsonString(source))
	}





	open func objectFromJsonStringObject(_ source: AnyObject) -> StructType? {
		return objectFromJsonObject(decodeJsonString(source))
	}





	open func listFromJsonStringParameterRecordset(_ source: AnyObject) -> StructType? {
		return listFromJsonParameterRecordset(decodeJsonString(source))
	}




	open func jsonStringRecordFromObject(_ source: StructType?) -> AnyObject {
		return encodeJsonString(jsonRecordFromObject(source))
	}





	open func jsonStringRecordsetFromList(_ list: [StructType]) -> AnyObject {
		return encodeJsonString(jsonRecordsetFromList(list))
	}





	open func jsonStringObjectFromObject(_ source: StructType?) -> AnyObject {
		return encodeJsonString(jsonObjectFromObject(source))
	}


	// MARK: - Internals


	typealias FieldBinding = (index:Int, field:CloudApiFieldConverter<StructType>)


	fileprivate func createFieldBindings(_ source: [String:AnyObject]) -> [FieldBinding] {
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





	fileprivate func jsonSchema() -> [AnyObject] {
		var schema = [AnyObject]()
		for field in fields {
			var fieldSchema = [String: AnyObject]()
			fieldSchema["n"] = field.cloudName as AnyObject?
			fieldSchema["t"] = field.cloudTypeName as AnyObject?
			schema.append(fieldSchema as AnyObject)
		}
		return schema
	}





	fileprivate func objectFromJsonRecordData(_ source: [AnyObject], _ bindings: [FieldBinding]) -> StructType {
		let object = objectFactory()
		for binding in bindings {
			binding.field.fieldSetter(object, source[binding.index])
		}
		return object
	}




	fileprivate func jsonRecordDataFromObject(_ object: StructType) -> [AnyObject] {
		var data = [AnyObject]()
		for field in fields {
			data.append(field.fieldGetter(object) ?? NSNull())
		}
		return data
	}




	fileprivate func decodeJsonString(_ source: AnyObject) -> AnyObject {
		guard let string = source as? String else {
			return source
		}
		let encoded = string.data(using: String.Encoding.utf8)!
		do {
			return try JSONSerialization.jsonObject(with: encoded, options: [])
		} catch let error as NSError {
			print("decodeJsonError: \(error)")
			print("Invalid JSON:\n--------------------------------------\n\(string)\n--------------------------------------\nWe try to fix it")
			do {
				return try Scanner.parseJson(string)
			} catch let fixError {
				print(fixError)
			}
		}
		return NSNull()
	}




	fileprivate func encodeJsonString(_ source: AnyObject) -> AnyObject {
		guard source is [AnyObject] || source is [String:AnyObject] else {
			return source
		}
		let encoded = try! JSONSerialization.data(withJSONObject: source, options: [])
		return String(data: encoded, encoding: String.Encoding.utf8)! as AnyObject
	}
}
