//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class DatabaseValueReader<Value>: GeneratorType {
	public typealias Element = Value

	let statement: DatabaseSelectStatement
	let reader: DatabaseReader
	let readValue: (DatabaseReader) -> Value?

	init(database: StorageDatabase, sql: String, setParams: (DatabaseSelectStatement) -> Void, readValue: (DatabaseReader) -> Value?) throws {
		statement = try database.createSelectStatement(sql)
		setParams(statement)
		reader = try statement.execute()
		self.readValue = readValue
	}

	deinit {
		reader.close()
		statement.close()
	}


	@warn_unused_result public func next() -> Element? {
		while reader.read() {
			let readed = readValue(reader)
			if readed != nil {
				return readed
			}
		}
		return nil
	}

}


public class DatabaseValueSequence<Value>: SequenceType {
	typealias Element = Value

	private let database: StorageDatabase
	private let sql: String
	private let setParams: (DatabaseSelectStatement) -> Void
	private let readValue: (DatabaseReader) -> Value?

	init(database: StorageDatabase, sql: String, setParams: (DatabaseSelectStatement) -> Void, readValue: (DatabaseReader) -> Value?) {
		self.database = database
		self.sql = sql
		self.setParams = setParams
		self.readValue = readValue
	}

	@warn_unused_result public func generate() -> DatabaseValueReader<Value> {
		return try! DatabaseValueReader(database: database, sql: sql, setParams: setParams, readValue: readValue)
	}
}


public class DatabaseRecordReader<Record>: GeneratorType {
	public typealias Element = Record

	let statement: DatabaseSelectStatement
	let reader: DatabaseReader
	let readRecord: (DatabaseReader, Record) -> Void
	var record: Record

	init(database: StorageDatabase, sql: String, record: Record, setParams: (DatabaseSelectStatement) -> Void, readRecord: (DatabaseReader, Record) -> Void) throws {
		statement = try database.createSelectStatement(sql)
		setParams(statement)
		reader = try statement.execute()
		self.readRecord = readRecord
		self.record = record
	}

	deinit {
		reader.close()
		statement.close()
	}


	@warn_unused_result public func next() -> Element? {
		guard reader.read() else {
			return nil
		}
		readRecord(reader, record)
		return record
	}

}


public class DatabaseRecordSequence<Record>: SequenceType {
	typealias Element = Record

	private let database: StorageDatabase
	private let sql: String
	private let record: Record
	private let setParams: (DatabaseSelectStatement) -> Void
	private let readRecord: (DatabaseReader, Record) -> Void

	init(database: StorageDatabase, sql: String, record: Record, setParams: (DatabaseSelectStatement) -> Void, readRecord: (DatabaseReader, Record) -> Void) {
		self.database = database
		self.sql = sql
		self.record = record
		self.setParams = setParams
		self.readRecord = readRecord
	}

	@warn_unused_result public func generate() -> DatabaseRecordReader<Record> {
		return try! DatabaseRecordReader(database: database, sql: sql, record: record, setParams: setParams, readRecord: readRecord)
	}
}


public enum DatabaseRecordFieldFilter {
	case All, Key, NonKey
}

public class DatabaseRecordField<Record> {
	public typealias ParamSetter = (DatabaseUpdateStatement, Int, Record) -> Void

	public let name: String
	public let isKey: Bool
	public let paramSetter: ParamSetter
	init(_ name: String, _ isKey: Bool, _ paramSetter: ParamSetter) {
		self.name = name
		self.isKey = isKey
		self.paramSetter = paramSetter
	}
}


public class DatabaseSqlFactory<Record> {
	typealias ReaderGetter = (Record, DatabaseReader, Int) -> Void
	typealias ParamSetter = (DatabaseUpdateStatement, Int, Record) -> Void
	typealias SqlWithFields = (String, [DatabaseRecordField<Record>])

	let tableName: String
	let getFieldSet: (Record) -> Int
	let fields: [DatabaseRecordField<Record>]
	let create: (Int, DatabaseSqlFactory<Record>) -> SqlWithFields
	let lock = NSLock()

	init(_ tableName: String, _ getFieldSet: (Record) -> Int, _ fields: [DatabaseRecordField<Record>], create: (Int, DatabaseSqlFactory<Record>) -> SqlWithFields) {
		self.tableName = tableName
		self.getFieldSet = getFieldSet
		self.fields = fields
		self.create = create
	}

	var cache = [Int: SqlWithFields]()

	func iterateFieldSet(fieldSet: Int, _ filter: DatabaseRecordFieldFilter, _ iterate: (DatabaseRecordField<Record>, Bool) -> Void) {
		var flag = 1
		var isFirst = true
		for index in 0 ..< fields.count {
			if (flag & fieldSet) != 0 {
				let field = fields[index]
				if filter == .All || field.isKey == (filter == .Key) {
					iterate(field, isFirst)
					isFirst = false
				}
			}
			flag *= 2
		}
	}


	func get(fieldSet: Int) -> SqlWithFields {
		lock.lock()
		defer {
			lock.unlock()
		}
		if let cached = cache[fieldSet] {
			return cached
		}

		let created = create(fieldSet, self)
		cache[fieldSet] = created
		return created
	}

	func createInsert(fieldSet: Int) -> DatabaseSqlFactory<Record>.SqlWithFields {
		var insertSection = "INSERT INTO \(tableName)("
		var valuesSection = ") VALUES ("

		var fields = [DatabaseRecordField < Record>]()
		iterateFieldSet(fieldSet, .All) {
			field, isFirst in
			if !isFirst {
				insertSection += ", "
				valuesSection += ", "
			}
			insertSection += "\(field.name)"
			valuesSection += "?"
			fields.append(field)
		}
		return (insertSection + valuesSection + ")", fields)
	}

	func createUpdate(fieldSet: Int) -> DatabaseSqlFactory<Record>.SqlWithFields {
		var sql = "UPDATE \(tableName) SET "
		var fields = [DatabaseRecordField < Record>]()
		iterateFieldSet(fieldSet, .NonKey) {
			field, isFirst in
			if !isFirst {
				sql += ", "
			}
			sql += "\(field.name)=?"
			fields.append(field)
		}
		sql += " WHERE "
		iterateFieldSet(fieldSet, .Key) {
			field, isFirst in
			if !isFirst {
				sql += " AND "
			}
			sql += "\(field.name)=?"
			fields.append(field)
		}
		return (sql, fields)
	}

	func createDelete(fieldSet: Int) -> DatabaseSqlFactory<Record>.SqlWithFields {
		var sql = "DELETE FROM \(tableName) WHERE "
		var fields = [DatabaseRecordField < Record>]()
		iterateFieldSet(fieldSet, .All) {
			field, isFirst in
			if !isFirst {
				sql += " AND "
			}
			sql += "\(field.name)=?"
			fields.append(field)
		}
		return (sql, fields)
	}

}




public class DatabaseStatementFactory<Record> {
	typealias StatementWithFields = (DatabaseUpdateStatement, [DatabaseRecordField<Record>])

	let database: StorageDatabase
	let sqlFactory: DatabaseSqlFactory<Record>
	var cache = [Int: StatementWithFields]()

	init(_ database: StorageDatabase, _ factory: DatabaseSqlFactory<Record>) {
		self.database = database
		self.sqlFactory = factory
	}


	func get(fieldSet: Int) -> StatementWithFields {
		if let cached = cache[fieldSet] {
			return cached
		}
		let (sql, fields) = sqlFactory.get(fieldSet)
		let created = (try! database.createUpdateStatement(sql), fields)
		cache[fieldSet] = created
		return created
	}

	func execute(record: Record) -> Void {
		let (statement, fields) = get(sqlFactory.getFieldSet(record))
		for index in 0 ..< fields.count {
			fields[index].paramSetter(statement, index, record)
		}
		try! statement.execute()
	}


	func execute(records: [Record]) -> Void {
		for record in records {
			execute(record)
		}
	}
}


public class DatabaseRecordSqlFactory<Record> {
	public let updates: DatabaseSqlFactory<Record>
	public let inserts: DatabaseSqlFactory<Record>
	public let deletes: DatabaseSqlFactory<Record>
	init(_ tableName: String, _ getFieldSet: (Record) -> Int, _ fields: [DatabaseRecordField<Record>]) {
		updates = DatabaseSqlFactory<Record>(tableName, getFieldSet, fields) {
			fieldSet, factory in return factory.createUpdate(fieldSet)
		}
		inserts = DatabaseSqlFactory<Record>(tableName, getFieldSet, fields) {
			fieldSet, factory in return factory.createInsert(fieldSet)
		}
		deletes = DatabaseSqlFactory<Record>(tableName, getFieldSet, fields) {
			fieldSet, factory in return factory.createDelete(fieldSet)
		}
	}
}



public class DatabaseRecordStatementFactory<Record> {
	let database: StorageDatabase
	let updates: DatabaseStatementFactory<Record>
	let inserts: DatabaseStatementFactory<Record>
	let deletes: DatabaseStatementFactory<Record>

	init(_ database: StorageDatabase, _ factory: DatabaseRecordSqlFactory<Record>) {
		self.database = database
		updates = DatabaseStatementFactory<Record>(database, factory.updates)
		inserts = DatabaseStatementFactory<Record>(database, factory.inserts)
		deletes = DatabaseStatementFactory<Record>(database, factory.deletes)
	}
}


extension StorageDatabase {
	public func iterateRecords<Record>(sql: String,
		record: Record,
		setParams: (DatabaseSelectStatement) -> Void,
		readRecord: (DatabaseReader, Record) -> Void) throws -> DatabaseRecordSequence<Record> {

		return DatabaseRecordSequence(database: self, sql: sql, record: record, setParams: setParams, readRecord: readRecord)
	}

	public func iterateValues<Value>(sql: String,
		setParams: (DatabaseSelectStatement) -> Void,
		readValue: (DatabaseReader) -> Value?) throws -> DatabaseValueSequence<Value> {

		return DatabaseValueSequence(database: self, sql: sql, setParams: setParams, readValue: readValue)
	}
}
