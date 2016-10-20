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

	private var fieldByCloudName = [String: CloudApiFieldConverter < StructType>]()





	public init(_ objectFactory: @escaping ObjectFactory, _ fields: [CloudApiFieldConverter<StructType>]) {
		self.objectFactory = objectFactory
		self.fields = fields
		for field in fields {
			fieldByCloudName[field.cloudName] = field
		}
	}





	open func objectFromJsonRecord(_ source: Any) -> StructType? {
		guard let sourceObject = source as? [String:Any] else {
			return nil
		}
		guard let data = sourceObject["d"] as? [Any] else {
			return nil
		}
		if data.count == 0 {
			return nil
		}
		return objectFromJsonRecordData(data, createFieldBindings(sourceObject))
	}





	open func listFromJsonRecordset(_ source: Any) -> [StructType?] {
		var objects = [StructType?]()
		if let sourceObject = source as? [String:Any] {
			if let table = sourceObject["d"] as? [Any] {
				let bindings = createFieldBindings(sourceObject)
				for record in table {
					let recordArray = record as! [AnyObject]
					objects.append(objectFromJsonRecordData(recordArray, bindings))
				}
			}
		}
		return objects
	}





	open func listFromJsonArray(_ source: Any) -> [StructType?] {
		var objects = [StructType?]()
		guard let sourceArray = source as? [Any] else {
			return objects
		}
		for value in sourceArray {
			if let object = objectFromJsonObject(value) {
				objects.append(object)
			}
		}
		return objects
	}





	open func objectFromJsonObject(_ source: Any) -> StructType? {
		guard let sourceObject = source as? [String:Any] else {
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





	open func listFromJsonParameterRecordset(_ source: Any) -> StructType? {

		let object = objectFactory()
		let values = CloudApiParameterValue.converter.listFromJsonRecordset(source)
		for value in values {
			if let value = value, let field = fieldByCloudName[value.parameter ?? ""] {
				field.fieldSetter(object, value.value ?? NSNull())
			}
		}
		return object
	}





	open func jsonRecordFromObject(_ source: StructType?) -> Any {
		guard let source = source else {
			return NSNull()
		}
		var record = [String: Any]()
		record["s"] = jsonSchema()
		record["d"] = jsonRecordDataFromObject(source)
		record["_type"] = "record"
		return record
	}





	open func jsonRecordsetFromList(_ list: [StructType?]) -> Any {
		var data = [Any]()
		for object in list {
			data.append(jsonRecordDataFromObject(object))
		}
		var recordset = [String: Any]()
		recordset["s"] = jsonSchema()
		recordset["d"] = data
		recordset["_type"] = "table"
		return recordset
	}





	open func jsonArrayFromList(_ list: [StructType?]) -> Any {
		var array = [Any]()
		for object in list {
			array.append(jsonObjectFromObject(object))
		}
		return array
	}





	open func jsonObjectFromObject(_ source: StructType?) -> Any {
		guard source != nil else {
			return NSNull()
		}
		var result = [String: Any]()
		for field in fields {
			result[field.cloudName] = field.fieldGetter(source!)
		}
		return result
	}


	open func objectFromJsonStringRecord(_ source: Any) -> StructType? {
		return objectFromJsonRecord(decodeJsonString(source))
	}





	open func listFromJsonStringRecordset(_ source: Any) -> [StructType?] {
		return listFromJsonRecordset(decodeJsonString(source))
	}





	open func objectFromJsonStringObject(_ source: Any) -> StructType? {
		return objectFromJsonObject(decodeJsonString(source))
	}





	open func listFromJsonStringParameterRecordset(_ source: Any) -> StructType? {
		return listFromJsonParameterRecordset(decodeJsonString(source))
	}




	open func jsonStringRecordFromObject(_ source: StructType?) -> Any {
		return encodeJsonString(jsonRecordFromObject(source))
	}





	open func jsonStringRecordsetFromList(_ list: [StructType?]) -> Any {
		return encodeJsonString(jsonRecordsetFromList(list))
	}





	open func jsonStringObjectFromObject(_ source: StructType?) -> Any {
		return encodeJsonString(jsonObjectFromObject(source))
	}


	// MARK: - Internals


	typealias FieldBinding = (index:Int, field:CloudApiFieldConverter<StructType>)


	
	private func createFieldBindings(_ source: [String:Any]) -> [FieldBinding] {
		var bindings = [FieldBinding]()
		if let schemaArray = source["s"] as? [Any] {
			var index = 0
			for schemaItem in schemaArray {
				if let fieldSchema = schemaItem as? [String:Any] {
					if let field = fieldByCloudName[fieldSchema["n"] as? String ?? ""] {
						bindings.append((index, field))
					}
				}
				index += 1
			}
		}
		return bindings
	}





	private func jsonSchema() -> [Any] {
		var schema = [Any]()
		for field in fields {
			var fieldSchema = [String: Any]()
			fieldSchema["n"] = field.cloudName
			fieldSchema["t"] = field.cloudTypeName
			schema.append(fieldSchema)
		}
		return schema
	}





	private func objectFromJsonRecordData(_ source: [Any], _ bindings: [FieldBinding]) -> StructType {
		let object = objectFactory()
		for binding in bindings {
			binding.field.fieldSetter(object, source[binding.index])
		}
		return object
	}




	private func jsonRecordDataFromObject(_ object: StructType?) -> Any {
		guard let object = object else {
			return NSNull()
		}
		var data = [Any]()
		for field in fields {
			data.append(field.fieldGetter(object))
		}
		return data
	}




	private func decodeJsonString(_ source: Any) -> Any {
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




	private func encodeJsonString(_ source: Any) -> Any {
		guard source is [Any] || source is [String:Any] else {
			return source
		}
		let encoded = try! JSONSerialization.data(withJSONObject: source, options: [])
		return String(data: encoded, encoding: String.Encoding.utf8)!
	}
}
