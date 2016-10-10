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





public class CloudApiPrimitiveTypeConverter {

	open static func uuidFromJson(_ value: Any) -> Uuid? {
		switch value {
			case let uuid as Uuid: return uuid
			case let string as String: return Uuid(uuidString: string)
			default: return nil
		}
	}



	open static func jsonFromUuid(_ value: Uuid?) -> Any {
		return value?.uuidString ?? NSNull()
	}

	
	open static func uuidArrayFromJsonArray(_ array: Any) -> [Uuid?] {
		return arrayFromJson(array) {
			item in uuidFromJson(item)
		}
	}



	open static func jsonArrayFromUuidArray(_ array: [Uuid?]) -> Any {
		return jsonFromArray(array) {
			item in jsonFromUuid(item)
		}
	}



	open static func integerFromJson(_ value: Any) -> Int? {
		switch value {
			case let s as String: return Int(s)
			case let i as Int: return i
			default: return nil
		}
	}



	open static func jsonFromInteger(_ value: Int?) -> Any {
		return value ?? NSNull()
	}



	open static func integerArrayFromJsonArray(_ array: Any) -> [Int?] {
		return arrayFromJson(array) {
			item in integerFromJson(item)
		}
	}



	open static func jsonArrayFromIntegerArray(_ array: [Int?]) -> Any {
		return jsonFromArray(array) {
			item in jsonFromInteger(item)
		}
	}



	open static func int64FromJson(_ value: Any) -> Int64? {
		switch value {
			case let s as String: return Int64(s)
			case let i64 as Int64: return i64
			case let i as Int: return Int64(i)
			default: return nil
		}
	}



	open static func jsonFromInt64(_ value: Int64?) -> Any {
		return value != nil ? String(value!) : NSNull()
	}



	fileprivate static func boolFromString(_ s: String) -> Bool? {
		switch s.lowercased() {
			case "1", "t", "true": return true
			case "0", "f", "false": return false
			default: return nil
		}
	}



	open static func booleanFromJson(_ value: Any) -> Bool? {
		switch value {
			case let s as String: return boolFromString(s)
			case let b as Bool: return b
			default: return nil
		}
	}



	open static func jsonFromBoolean(_ value: Bool?) -> Any {
		return value ?? NSNull()
	}



	open static func booleanArrayFromJsonArray(_ array: Any) -> [Bool?] {
		return arrayFromJson(array) {
			item in booleanFromJson(item)
		}
	}



	open static func jsonArrayFromBooleanArray(_ array: [Bool?]) -> Any {
		return jsonFromArray(array) {
			item in jsonFromBoolean(item)
		}
	}



	open static func stringFromJson(_ value: Any) -> String? {
		switch value {
			case is NSNull: return nil
			case let s as String: return s
			default: return String(describing: value)
		}
	}



	open static func jsonFromString(_ value: String?) -> Any {
		return value ?? NSNull()
	}



	open static func stringArrayFromJsonArray(_ array: Any) -> [String?] {
		return arrayFromJson(array) {
			item in stringFromJson(item)
		}
	}



	open static func jsonArrayFromStringArray(_ array: [String?]) -> Any {
		return jsonFromArray(array) {
			item in jsonFromString(item)
		}
	}


	open static var dateTimeConversionDefaultCalendar: Calendar = {
		var calendar: Calendar! = Calendar(identifier: Calendar.current.identifier)
		calendar.timeZone = TimeZone(secondsFromGMT: 3 * 60 * 60)!
		return calendar
	}()


	fileprivate static func createDateTimeFormatter(_ format: String, withTodayAsDefaultDate: Bool) -> DateFormatter {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = format
		formatter.timeZone = dateTimeConversionDefaultCalendar.timeZone
		if withTodayAsDefaultDate {
			formatter.defaultDate = dateTimeConversionDefaultCalendar.startOfDay(for: Date())
		}
		return formatter
	}

	fileprivate static var defaultDateTimeFormatter = CloudApiPrimitiveTypeConverter.createDateTimeFormatter("yyyy-MM-dd HH:mm:ssx", withTodayAsDefaultDate: false)
	fileprivate static var dateTimeFormatterWithMilliseconds = CloudApiPrimitiveTypeConverter.createDateTimeFormatter("yyyy-MM-dd HH:mm:ss.SSSx", withTodayAsDefaultDate: false)
	fileprivate static var dateFormatter: DateFormatter {
		return createDateTimeFormatter("yyyy-MM-dd", withTodayAsDefaultDate: true)
	}
	fileprivate static var dotSeparatedDateTimeFormatter: DateFormatter {
		return createDateTimeFormatter("dd.MM.yyyy HH.mm.ss", withTodayAsDefaultDate: true)
	}

	fileprivate static var dotSeparatedDateFormatter: DateFormatter {
		return createDateTimeFormatter("dd.MM.yy", withTodayAsDefaultDate: true)
	}

	fileprivate static var dotSeparatedDayMonthFormatter: DateFormatter {
		return createDateTimeFormatter("dd.MM", withTodayAsDefaultDate: true)
	}


	open static func dateTimeFromJson(_ value: Any) -> Date? {
		switch value {
			case let string as String:
				if let date = defaultDateTimeFormatter.date(from: string) {
					return date
				}
				if let date = dateTimeFormatterWithMilliseconds.date(from: string) {
					return date
				}
				if let date = dateFormatter.date(from: string) {
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



	open static func jsonFromDateTime(_ value: Date?) -> Any {
		guard let value = value else {
			return NSNull()
		}
		return defaultDateTimeFormatter.string(from: value)
	}



	open static func arrayFromJson<T>(_ source: Any, _ loadItem: (_:Any) -> T?) -> [T?] {
		var result = [T?]()
		if let sourceArray = source as? [Any] {
			for sourceItem in sourceArray {
				if !(sourceItem is NSNull) {
					result.append(loadItem(sourceItem))
				}
			}
		}
		return result
	}



	open static func jsonFromArray<T>(_ source: [T?], _ saveItem: (_:T?) -> Any) -> Any {
		var array = [Any]()
		for sourceItem in source {
			array.append(saveItem(sourceItem))
		}
		return array
	}
}




