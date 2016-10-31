//
// Created by Власов М.Ю. on 31.10.16.
//

import Foundation


public class SbisDecoder {


	public static func jsonObject<T>(_ value: Any, type: SbisType<T>) -> T? {
		guard let jsonObject = value as? [String: Any] else {
			return nil
		}
		return type.decode(SbisValues.fromJsonObject(type.fields, jsonObject))
	}



	public static func sbisRecord<T>(_ value: Any, type: SbisType<T>) -> T? {
		guard let (indexes, values) = getIndexesAndValues(source: value, fields: type.fields) else {
			return nil
		}
		return type.decode(SbisValues.fromSbisRecord(indexes, values))
	}



	public static func jsonArray<T>(_ value: Any, type: SbisType<T>) -> [T?] {
		var result = [T?]()
		guard let jsonArray = value as? [Any] else {
			return result
		}
		for jsonItem in jsonArray {
			if let jsonObject = jsonItem as? [String: Any] {
				result.append(type.decode(SbisValues.fromJsonObject(type.fields, jsonObject)))
			}
			else {
				result.append(nil)
			}
		}
		return result
	}



	public static func sbisRecordset<T>(_ value: Any, type: SbisType<T>) -> [T?] {
		var result = [T?]()
		guard let (indexes, values) = getIndexesAndValues(source: value, fields: type.fields) else {
			return result
		}
		for recordValues in values {
			if let recordValues = recordValues as? [Any] {
				result.append(type.decode(SbisValues.fromSbisRecord(indexes, recordValues)))
			}
			else {
				result.append(nil)
			}
		}
		return result
	}



	private static func getIndexesAndValues(source: Any, fields: [String]) -> ([Int], [Any])? {
		guard let dict = source as? [String: Any], let s = dict["s"] as? [Any], let d = dict["d"] as? [Any] else {
			return nil
		}
		var dataIndexByLowercaseName = [String: Int]()
		var index = 0
		for schemaField in s {
			if let schemaField = schemaField as? [String: Any], let name = schemaField["n"] as? String {
				dataIndexByLowercaseName[name.lowercased()] = index
			}
			index += 1
		}
		var indexes = [Int](repeating: -1, count: fields.count)
		index = 0
		for field in fields {
			if let dataIndex = dataIndexByLowercaseName[field.lowercased()] {
				indexes[index] = dataIndex
			}
			index += 1
		}
		return (indexes, d)
	}

}
