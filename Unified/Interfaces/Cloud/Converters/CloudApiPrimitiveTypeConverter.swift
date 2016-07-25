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




	private static var dayMonthFormatter: NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "dd.MM"
		return formatter
	}()


	private static var dateTimeFormatter: NSDateFormatter = {
		let RFC3339 = NSDateFormatter()
		RFC3339.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		RFC3339.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSx"
		RFC3339.timeZone = NSTimeZone(forSecondsFromGMT: 0)

		return RFC3339
	}()


	private static var dateTimeFormatterWithTimeZone: NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ssx"
		return formatter
	}()





	public static func dateTimeFromJson(value: AnyObject) -> NSDate? {
		switch value {
			case let s as String:
				if let date = dateTimeFormatterWithTimeZone.dateFromString(s) {
					return date
				}
				if let date = dateTimeFormatter.dateFromString(s) {
					return date
				}
				if let date = dayMonthFormatter.dateFromString(s) {
					let calendar = NSCalendar.currentCalendar()
					let todayComponents = calendar.components([.Year], fromDate: NSDate())
					let components = calendar.components([.Month, .Day], fromDate: date)
					components.year = todayComponents.year
					let resultDate = calendar.dateFromComponents(components)
					return resultDate
				}
				print("can not convert date from string: \(s)")
				return nil
			default: return nil
		}
	}





	public static func jsonFromDateTime(value: NSDate?) -> AnyObject {
		return value != nil ? dateTimeFormatter.stringFromDate(value!) : NSNull()
	}



	public static func arrayFromJson<T>(source: AnyObject, _ loadItem: (_:AnyObject) -> T?) -> [T?] {
		var result = [T?]()
		if let sourceArray = source as? [AnyObject] {
			for sourceItem in sourceArray {
				result.append(sourceItem is NSNull ? nil : loadItem(sourceItem))
			}
		}
		return result
	}





	public static func jsonFromArray<T>(source: [T?], _ saveItem: (_:T) -> AnyObject) -> [AnyObject] {
		var array = [AnyObject]()
		for sourceItem in source {
			array.append(sourceItem == nil ? NSNull() : saveItem(sourceItem!))
		}
		return array
	}
}
