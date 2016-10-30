//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public typealias Uuid = UUID

public let UuidZero = NSUUID(uuidBytes: [UInt8](repeating: 0, count: 16)) as UUID



extension Uuid {

	public static func same(_ a: Uuid?, _ b: Uuid?) -> Bool {
		if a == nil && b == nil {
			return true
		}
		if a == nil || b == nil {
			return false
		}
		return a! == b!
	}
}



extension String {

	public func toUuid() -> Uuid? {
		return !isEmpty ? Uuid(uuidString: self) : nil
	}



	public static func fromUuid(_ value: Uuid?) -> String {
		return value != nil ? value!.uuidString : ""
	}
}



public class JsonDecoder {


	// UUID


	public static func uuid(_ value: Any) -> Uuid? {
		switch value {
			case let uuid as Uuid: return uuid
			case let string as String: return Uuid(uuidString: string)
			default: return nil
		}
	}



	public static func uuidArray(_ value: Any) -> [Uuid?] {
		return array(value, item: uuid)
	}



	// Int


	public static func integer(_ value: Any) -> Int? {
		switch value {
			case let s as String: return Int(s)
			case let i as Int: return i
			default: return nil
		}
	}



	public static func integerArray(_ value: Any) -> [Int?] {
		return array(value, item: integer)
	}



	// Double


	public static func double(_ value: Any) -> Double? {
		switch value {
			case let s as String: return Double(s)
			case let d as Double: return d
			case let i as Int: return Double(i)
			default: return nil
		}
	}



	public static func doubleArray(_ value: Any) -> [Double?] {
		return array(value, item: double)
	}



	// Int64


	public static func int64(_ value: Any) -> Int64? {
		switch value {
			case let s as String: return Int64(s)
			case let i64 as Int64: return i64
			case let i as Int: return Int64(i)
			default: return nil
		}
	}



	public static func int64Array(_ value: Any) -> [Int64?] {
		return array(value, item: int64)
	}



	// Bool

	private static func boolFromString(_ s: String) -> Bool? {
		switch s.lowercased() {
			case "1", "t", "true": return true
			case "0", "f", "false": return false
			default: return nil
		}
	}



	public static func boolean(_ value: Any) -> Bool? {
		switch value {
			case let s as String: return boolFromString(s)
			case let b as Bool: return b
			default: return nil
		}
	}



	public static func booleanArray(_ value: Any) -> [Bool?] {
		return array(value, item: boolean)
	}



	// String


	public static func string(_ value: Any) -> String? {
		switch value {
			case is NSNull: return nil
			case let s as String: return s
			default: return String(describing: value)
		}
	}



	public static func stringArray(_ value: Any) -> [String?] {
		return array(value, item: string)
	}



	// DateTime


	public static var dateTimeConversionDefaultCalendar: Calendar = {
		var calendar: Calendar! = Calendar(identifier: Calendar.current.identifier)
		calendar.timeZone = TimeZone(secondsFromGMT: 3 * 60 * 60)!
		return calendar
	}()


	private static func createDateTimeFormatter(_ format: String, withTodayAsDefaultDate: Bool) -> DateFormatter {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = format
		formatter.timeZone = dateTimeConversionDefaultCalendar.timeZone
		if withTodayAsDefaultDate {
			formatter.defaultDate = dateTimeConversionDefaultCalendar.startOfDay(for: Date())
		}
		return formatter
	}

	public static var defaultDateTimeFormatter = JsonDecoder.createDateTimeFormatter("yyyy-MM-dd HH:mm:ssx", withTodayAsDefaultDate: false)
	private static var dateTimeFormatterWithMilliseconds = JsonDecoder.createDateTimeFormatter("yyyy-MM-dd HH:mm:ss.SSSx", withTodayAsDefaultDate: false)
	private static var dateFormatter: DateFormatter {
		return createDateTimeFormatter("yyyy-MM-dd", withTodayAsDefaultDate: true)
	}
	private static var dotSeparatedDateTimeFormatter: DateFormatter {
		return createDateTimeFormatter("dd.MM.yyyy HH.mm.ss", withTodayAsDefaultDate: true)
	}

	private static var dotSeparatedDateFormatter: DateFormatter {
		return createDateTimeFormatter("dd.MM.yy", withTodayAsDefaultDate: true)
	}

	private static var dotSeparatedDayMonthFormatter: DateFormatter {
		return createDateTimeFormatter("dd.MM", withTodayAsDefaultDate: true)
	}


	public static func dateTime(_ value: Any) -> Date? {
		switch value {
			case let string as String:
				if let date = defaultDateTimeFormatter.date(from: string) {
					return date
				}
				if let date = dateTimeFormatterWithMilliseconds.date(from: string) {
					return date
				}
				if string.contains("-"), let date = dateFormatter.date(from: string) {
					return date
				}
				if let date = dotSeparatedDateTimeFormatter.date(from: string) {
					return date
				}
				if let date = dotSeparatedDateFormatter.date(from: string) {
					return date
				}
				if let date = dotSeparatedDayMonthFormatter.date(from: string) {
					return date
				}

				print("can not convert date from string: \(string)")
				return nil
			default:
				return nil
		}
	}



	public static func dateTimeArray(_ value: Any) -> [Date?] {
		return array(value, item: dateTime)
	}



	// Array


	public static func array<T>(_ source: Any, item: (_: Any) -> T?) -> [T?] {
		var result = [T?]()
		if let sourceArray = source as? [Any] {
			for sourceItem in sourceArray {
				if !(sourceItem is NSNull) {
					result.append(item(sourceItem))
				}
			}
		}
		return result
	}
}



public class JsonEncoder {


	// UUID


	public static func uuid(_ value: Uuid?) -> Any {
		return value?.uuidString ?? NSNull()
	}



	public static func uuidArray(_ value: [Uuid?]) -> Any {
		return array(value, item: uuid)
	}


	// Int


	public static func integer(_ value: Int?) -> Any {
		return value ?? NSNull()
	}



	public static func integerArray(_ value: [Int?]) -> Any {
		return array(value, item: integer)
	}


	// Double


	public static func double(_ value: Double?) -> Any {
		return value ?? NSNull()
	}



	public static func doubleArray(_ value: [Double?]) -> Any {
		return array(value, item: double)
	}


	// Int64


	public static func int64(_ value: Int64?) -> Any {
		return value != nil ? String(value!) : NSNull()
	}



	public static func int64Array(_ value: [Int64?]) -> Any {
		return array(value, item: int64)
	}


	// Bool

	public static func boolean(_ value: Bool?) -> Any {
		return value ?? NSNull()
	}



	public static func booleanArray(_ value: [Bool?]) -> Any {
		return array(value, item: boolean)
	}


	// String


	public static func string(_ value: String?) -> Any {
		return value ?? NSNull()
	}



	public static func stringArray(_ value: [String?]) -> Any {
		return array(value, item: string)
	}


	// DateTime


	public static func dateTime(_ value: Date?) -> Any {
		guard let value = value else {
			return NSNull()
		}
		return JsonDecoder.defaultDateTimeFormatter.string(from: value)
	}



	public static func dateTimeArray(_ value: [Date?]) -> Any {
		return array(value, item: dateTime)
	}


	// Array


	public static func array<T>(_ source: [T?], item: (_: T?) -> Any) -> Any {
		var result = [Any]()
		for sourceItem in source {
			result.append(item(sourceItem))
		}
		return result
	}
}



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
