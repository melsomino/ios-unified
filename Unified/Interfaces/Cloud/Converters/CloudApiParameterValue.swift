//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class CloudApiParameterValue {
	var parameter: String?
	var value: String?

	open static let converter = CloudApiStructConverter<CloudApiParameterValue>({ CloudApiParameterValue() }, [
		CloudApiFieldConverter<CloudApiParameterValue>("Параметр", "Текст", { $0.parameter = JsonDecoder.string($1) }, { JsonEncoder.string($0.parameter) }),
		CloudApiFieldConverter<CloudApiParameterValue>("Значение", "Текст", { $0.value = JsonDecoder.string($1) }, { JsonEncoder.string($0.value) })
	])

}
