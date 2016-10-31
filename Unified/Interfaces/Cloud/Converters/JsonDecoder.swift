//
// Created by Власов М.Ю. on 31.10.16.
//

import Foundation

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
