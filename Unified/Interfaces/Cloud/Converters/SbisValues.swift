//
// Created by Власов М.Ю. on 31.10.16.
//

import Foundation


public class SbisType<T> {
	public let fields: [String]
	public let decode: (SbisValues) -> T

	public init(fields: [String], decode: @escaping (SbisValues) -> T) {
		self.fields = fields
		self.decode = decode
	}
}



public enum SbisValues {


	// Primitive Types


	public func integer(_ index: Int) -> Int? {
		return JsonDecoder.integer(self[index])
	}



	public func int64(_ index: Int) -> Int64? {
		return JsonDecoder.int64(self[index])
	}



	public func string(_ index: Int) -> String? {
		return JsonDecoder.string(self[index])
	}



	public func boolean(_ index: Int) -> Bool? {
		return JsonDecoder.boolean(self[index])
	}



	public func uuid(_ index: Int) -> Uuid? {
		return JsonDecoder.uuid(self[index])
	}



	public func dateTime(_ index: Int) -> Date? {
		return JsonDecoder.dateTime(self[index])
	}


	// Primitive Type Arrays


	public func integerArray(_ index: Int) -> [Int?] {
		return JsonDecoder.integerArray(self[index])
	}



	public func stringArray(_ index: Int) -> [String?] {
		return JsonDecoder.stringArray(self[index])
	}



	public func booleanArray(_ index: Int) -> [Bool?] {
		return JsonDecoder.booleanArray(self[index])
	}



	public func uuidArray(_ index: Int) -> [Uuid?] {
		return JsonDecoder.uuidArray(self[index])
	}



	public func dateTimeArray(_ index: Int) -> [Date?] {
		return JsonDecoder.dateTimeArray(self[index])
	}


	// Struct Types


	public func jsonObject<T>(_ index: Int, type: SbisType<T>) -> T? {
		return SbisDecoder.jsonObject(self[index], type: type)
	}


	public func stringWithJsonObject<T>(_ index: Int, type: SbisType<T>) -> T? {
		guard let stringValue = string(index) else {
			return nil
		}
		guard let jsonData = stringValue.data(using: .utf8) else {
			return nil
		}
		var jsonValue: Any
		do {
			jsonValue = try JSONSerialization.jsonObject(with: jsonData)
		} catch let error {
			print(error)
			do {
				jsonValue = try Scanner.parseJson(stringValue)
			}
			catch let error {
				print(error)
				return nil
			}
		}
		return SbisDecoder.jsonObject(jsonValue, type: type)
	}



	public func sbisRecord<T>(_ index: Int, type: SbisType<T>) -> T? {
		return SbisDecoder.sbisRecord(self[index], type: type)
	}



	public func jsonArray<T>(_ index: Int, type: SbisType<T>) -> [T?] {
		return SbisDecoder.jsonArray(self[index], type: type)
	}



	public func sbisRecordset<T>(_ index: Int, type: SbisType<T>) -> [T?] {
		return SbisDecoder.sbisRecordset(self[index], type: type)
	}


	// Internals

	public subscript(index: Int) -> Any {
		switch self {
			case .fromJsonObject(let names, let values):
				return values[names[index]] ?? NSNull()
			case .fromSbisRecord(let indexes, let values):
				let valueIndex = indexes[index]
				return valueIndex >= 0 ? values[valueIndex] : NSNull()
		}
	}



	case fromSbisRecord([Int], [Any])
	case fromJsonObject([String], [String: Any])
}
