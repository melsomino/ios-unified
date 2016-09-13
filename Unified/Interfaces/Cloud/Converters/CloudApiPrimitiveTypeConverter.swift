//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public typealias Uuid = NSUUID





extension String {

	public func toUuid() -> Uuid? {
		return !isEmpty ? Uuid(UUIDString: self) : nil
	}



	public static func fromUuid(value: Uuid?) -> String {
		return value != nil ? value!.UUIDString : ""
	}
}





public class CloudApiPrimitiveTypeConverter {

	public static func uuidFromJson(value: AnyObject) -> Uuid? {
		switch value {
			case let uuid as Uuid: return uuid
			case let string as String: return Uuid(UUIDString: string)
			default: return nil
		}
	}



	public static func jsonFromUuid(value: Uuid?) -> AnyObject {
		return value?.UUIDString ?? NSNull()
	}



	public static func integerFromJson(value: AnyObject) -> Int? {
		switch value {
			case let s as String: return Int(s)
			case let i as Int: return i
			default: return nil
		}
	}



	public static func jsonFromInteger(value: Int?) -> AnyObject {
		return value ?? NSNull()
	}



	public static func integerArrayFromJsonArray(array: AnyObject) -> [Int] {
		return arrayFromJson(array) {
			item in integerFromJson(item) ?? 0
		}
	}



	public static func jsonArrayFromIntegerArray(array: [Int]) -> AnyObject {
		return jsonFromArray(array) {
			item in jsonFromInteger(item)
		}
	}



	public static func int64FromJson(value: AnyObject) -> Int64? {
		switch value {
			case let s as String: return Int64(s)
			case let i64 as Int64: return i64
			case let i as Int: return Int64(i)
			default: return nil
		}
	}



	public static func jsonFromInt64(value: Int64?) -> AnyObject {
		return value != nil ? String(value!) : NSNull()
	}



	private static func boolFromString(s: String) -> Bool? {
		switch s.lowercaseString {
			case "1", "t", "true": return true
			case "0", "f", "false": return false
			default: return nil
		}
	}



	public static func booleanFromJson(value: AnyObject) -> Bool? {
		switch value {
			case let s as String: return boolFromString(s)
			case let b as Bool: return b
			default: return nil
		}
	}



	public static func jsonFromBoolean(value: Bool?) -> AnyObject {
		return value ?? NSNull()
	}



	public static func stringFromJson(value: AnyObject) -> String? {
		switch value {
			case is NSNull: return nil
			case let s as String: return s
			default: return String(value)
		}
	}



	public static func jsonFromString(value: String?) -> AnyObject {
		return value ?? NSNull()
	}



	public static func stringArrayFromJsonArray(array: AnyObject) -> [String] {
		return arrayFromJson(array) {
			item in stringFromJson(item) ?? ""
		}
	}



	public static func jsonArrayFromStringArray(array: [String]) -> AnyObject {
		return jsonFromArray(array) {
			item in jsonFromString(item)
		}
	}


	public static var dateTimeConversionDefaultCalendar: NSCalendar = {
		var calendar: NSCalendar! = NSCalendar(identifier: NSCalendar.currentCalendar().calendarIdentifier)!
		calendar.timeZone = NSTimeZone(forSecondsFromGMT: 3 * 60 * 60)
		return calendar
	}()


	private static func createDateTimeFormatter(format: String, withTodayAsDefaultDate: Bool) -> NSDateFormatter {
		let formatter = NSDateFormatter()
		formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		formatter.dateFormat = format
		formatter.timeZone = dateTimeConversionDefaultCalendar.timeZone
		if withTodayAsDefaultDate {
			formatter.defaultDate = dateTimeConversionDefaultCalendar.startOfDayForDate(NSDate())
		}
		return formatter
	}

	private static var defaultDateTimeFormatter = CloudApiPrimitiveTypeConverter.createDateTimeFormatter("yyyy-MM-dd HH:mm:ssx", withTodayAsDefaultDate: false)
	private static var dateTimeFormatterWithMilliseconds = CloudApiPrimitiveTypeConverter.createDateTimeFormatter("yyyy-MM-dd HH:mm:ss.SSSx", withTodayAsDefaultDate: false)
	private static var dateFormatter: NSDateFormatter {
		return createDateTimeFormatter("yyyy-MM-dd", withTodayAsDefaultDate: true)
	}
	private static var dotSeparatedDateTimeFormatter: NSDateFormatter {
		return createDateTimeFormatter("dd.MM.yyyy HH.mm.ss", withTodayAsDefaultDate: true)
	}

	private static var dotSeparatedDateFormatter: NSDateFormatter {
		return createDateTimeFormatter("dd.MM.yy", withTodayAsDefaultDate: true)
	}

	private static var dotSeparatedDayMonthFormatter: NSDateFormatter {
		return createDateTimeFormatter("dd.MM", withTodayAsDefaultDate: true)
	}


	public static func dateTimeFromJson(value: AnyObject) -> NSDate? {
		switch value {
			case let string as String:
				if let date = defaultDateTimeFormatter.dateFromString(string) {
					return date
				}
				if let date = dateTimeFormatterWithMilliseconds.dateFromString(string) {
					return date
				}
				if let date = dateFormatter.dateFromString(string) {
					return date
				}
				if let date = dotSeparatedDateTimeFormatter.dateFromString(string) {
					return date
				}
				if let date = dotSeparatedDateFormatter.dateFromString(string) {
					return date
				}
				if let date = dotSeparatedDayMonthFormatter.dateFromString(string) {
					return date
				}

				print("can not convert date from string: \(string)")
				return nil
			default:
				return nil
		}
	}



	public static func jsonFromDateTime(value: NSDate?) -> AnyObject {
		return value != nil ? defaultDateTimeFormatter.stringFromDate(value!) : NSNull()
	}



	public static func arrayFromJson<T>(source: AnyObject, _ loadItem: (_:AnyObject) -> T) -> [T] {
		var result = [T]()
		if let sourceArray = source as? [AnyObject] {
			for sourceItem in sourceArray {
				if !(sourceItem is NSNull) {
					result.append(loadItem(sourceItem))
				}
			}
		}
		return result
	}



	public static func jsonFromArray<T>(source: [T], _ saveItem: (_:T) -> AnyObject) -> [AnyObject] {
		var array = [AnyObject]()
		for sourceItem in source {
			array.append(saveItem(sourceItem))
		}
		return array
	}
}
