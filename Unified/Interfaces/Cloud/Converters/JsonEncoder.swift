//
// Created by Власов М.Ю. on 31.10.16.
//

import Foundation

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

