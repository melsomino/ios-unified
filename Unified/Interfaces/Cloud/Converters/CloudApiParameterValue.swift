//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class CloudApiParameterValue {
	var parameter: String?
	var value: String?

	public static let converter = CloudApiStructConverter<CloudApiParameterValue>({ CloudApiParameterValue() }, [
		CloudApiFieldConverter<CloudApiParameterValue>("Параметр", "Текст",
			{ $0.parameter = CloudApiPrimitiveTypeConverter.stringFromJson($1) },
			{ CloudApiPrimitiveTypeConverter.jsonFromString($0.parameter) }),
		CloudApiFieldConverter<CloudApiParameterValue>("Значение", "Текст",
			{ $0.value = CloudApiPrimitiveTypeConverter.stringFromJson($1) },
			{ CloudApiPrimitiveTypeConverter.jsonFromString($0.value) })
	])

}
