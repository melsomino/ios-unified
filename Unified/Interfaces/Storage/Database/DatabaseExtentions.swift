//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation



open class DatabaseValueReader<Value>: IteratorProtocol {
	public typealias Element = Value

	let statement: DatabaseSelectStatement
	let reader: DatabaseReader
	let readValue: (DatabaseReader) -> Value?

	init(database: StorageDatabase, sql: String, setParams: (DatabaseSelectStatement) -> Void, readValue: @escaping (DatabaseReader) -> Value?) throws {
		statement = try database.createSelectStatement(sql)
		setParams(statement)
		reader = try statement.execute()
		self.readValue = readValue
	}

	deinit {
		reader.close()
		statement.close()
	}



	open func next() -> Element? {
		do {
			while try reader.read() {
				let readed = readValue(reader)
				if readed != nil {
					return readed
				}
			}
		}
		catch let error {
			fatalError("Database read error: \(error)")
		}
		return nil
	}

}



open class DatabaseValueSequence<Value>: Sequence {
	typealias Element = Value

	fileprivate let database: StorageDatabase
	fileprivate let sql: String
	fileprivate let setParams: (DatabaseSelectStatement) -> Void
	fileprivate let readValue: (DatabaseReader) -> Value?

	init(database: StorageDatabase, sql: String, setParams: @escaping (DatabaseSelectStatement) -> Void, readValue: @escaping (DatabaseReader) -> Value?) {
		self.database = database
		self.sql = sql
		self.setParams = setParams
		self.readValue = readValue
	}



	open func makeIterator() -> DatabaseValueReader<Value> {
		return try! DatabaseValueReader(database: database, sql: sql, setParams: setParams, readValue: readValue)
	}
}



open class DatabaseRecordReader<Record>: IteratorProtocol {
	public typealias Element = Record

	let statement: DatabaseSelectStatement
	let reader: DatabaseReader
	let readRecord: (DatabaseReader, Record) -> Void
	var record: Record

	init(database: StorageDatabase, sql: String, record: Record, setParams: (DatabaseSelectStatement) -> Void, readRecord: @escaping (DatabaseReader, Record) -> Void) throws {
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



	open func next() -> Element? {
		do {
			guard try reader.read() else {
				return nil
			}
		}
		catch let error {
			fatalError("Database read error: \(error)")
		}
		readRecord(reader, record)
		return record
	}

}



open class DatabaseRecordSequence<Record>: Sequence {
	typealias Element = Record

	fileprivate let database: StorageDatabase
	fileprivate let sql: String
	fileprivate let record: Record
	fileprivate let setParams: (DatabaseSelectStatement) -> Void
	fileprivate let readRecord: (DatabaseReader, Record) -> Void

	init(database: StorageDatabase, sql: String, record: Record, setParams: @escaping (DatabaseSelectStatement) -> Void, readRecord: @escaping (DatabaseReader, Record) -> Void) {
		self.database = database
		self.sql = sql
		self.record = record
		self.setParams = setParams
		self.readRecord = readRecord
	}



	open func makeIterator() -> DatabaseRecordReader<Record> {
		return try! DatabaseRecordReader(database: database, sql: sql, record: record, setParams: setParams, readRecord: readRecord)
	}
}



public enum DatabaseRecordFieldFilter {
	case all, key, nonKey
}



open class DatabaseRecordField<Record> {
	public typealias ParamSetter = (DatabaseUpdateStatement, Int, Record) -> Void

	open let name: String
	open let isKey: Bool
	open let paramSetter: ParamSetter
	public init(_ name: String, _ isKey: Bool, _ paramSetter: @escaping ParamSetter) {
		self.name = name
		self.isKey = isKey
		self.paramSetter = paramSetter
	}
}



open class DatabaseSqlFactory<Record> {
	typealias ReaderGetter = (Record, DatabaseReader, Int) -> Void
	typealias ParamSetter = (DatabaseUpdateStatement, Int, Record) -> Void
	typealias SqlWithFields = (String, [DatabaseRecordField<Record>])

	let tableName: String
	let getFieldSet: (Record) -> Int
	let fields: [DatabaseRecordField<Record>]
	let create: (Int, DatabaseSqlFactory<Record>) -> SqlWithFields
	let lock = NSLock()

	init(_ tableName: String, _ getFieldSet: @escaping (Record) -> Int, _ fields: [DatabaseRecordField<Record>], create: @escaping (Int, DatabaseSqlFactory<Record>) -> SqlWithFields) {
		self.tableName = tableName
		self.getFieldSet = getFieldSet
		self.fields = fields
		self.create = create
	}

	var cache = [Int: SqlWithFields]()

	func iterateFieldSet(_ fieldSet: Int, _ filter: DatabaseRecordFieldFilter, _ iterate: (DatabaseRecordField<Record>, Bool) -> Void) {
		var flag = 1
		var isFirst = true
		for index in 0 ..< fields.count {
			if (flag & fieldSet) != 0 {
				let field = fields[index]
				if filter == .all || field.isKey == (filter == .key) {
					iterate(field, isFirst)
					isFirst = false
				}
			}
			flag *= 2
		}
	}



	func get(_ fieldSet: Int) -> SqlWithFields {
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



	func createInsert(_ fieldSet: Int) -> DatabaseSqlFactory<Record>.SqlWithFields {
		var insertSection = "INSERT INTO \(tableName)("
		var valuesSection = ") VALUES ("

		var fields = [DatabaseRecordField<Record>]()
		iterateFieldSet(fieldSet, .all) {
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



	func createUpdate(_ fieldSet: Int) -> DatabaseSqlFactory<Record>.SqlWithFields {
		var sql = "UPDATE \(tableName) SET "
		var fields = [DatabaseRecordField<Record>]()
		iterateFieldSet(fieldSet, .nonKey) {
			field, isFirst in
			if !isFirst {
				sql += ", "
			}
			sql += "\(field.name)=?"
			fields.append(field)
		}
		sql += " WHERE "
		iterateFieldSet(fieldSet, .key) {
			field, isFirst in
			if !isFirst {
				sql += " AND "
			}
			sql += "\(field.name)=?"
			fields.append(field)
		}
		return (sql, fields)
	}



	func createDelete(_ fieldSet: Int) -> DatabaseSqlFactory<Record>.SqlWithFields {
		var sql = "DELETE FROM \(tableName) WHERE "
		var fields = [DatabaseRecordField<Record>]()
		iterateFieldSet(fieldSet, .all) {
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




open class DatabaseStatementFactory<Record> {
	typealias StatementWithFields = (DatabaseUpdateStatement, [DatabaseRecordField<Record>])

	let database: StorageDatabase
	let sqlFactory: DatabaseSqlFactory<Record>
	var cache = [Int: StatementWithFields]()

	init(_ database: StorageDatabase, _ factory: DatabaseSqlFactory<Record>) {
		self.database = database
		self.sqlFactory = factory
	}



	func get(_ fieldSet: Int) -> StatementWithFields {
		if let cached = cache[fieldSet] {
			return cached
		}
		let (sql, fields) = sqlFactory.get(fieldSet)
		let created = (try! database.createUpdateStatement(sql), fields)
		cache[fieldSet] = created
		return created
	}



	open func execute(_ record: Record) -> Void {
		let (statement, fields) = get(sqlFactory.getFieldSet(record))
		for index in 0 ..< fields.count {
			fields[index].paramSetter(statement, index, record)
		}
		try! statement.execute()
	}



	open func execute(_ records: [Record]) -> Void {
		for record in records {
			execute(record)
		}
	}
}



open class DatabaseRecordSqlFactory<Record> {
	open let updates: DatabaseSqlFactory<Record>
	open let inserts: DatabaseSqlFactory<Record>
	open let deletes: DatabaseSqlFactory<Record>
	public init(_ tableName: String, _ getFieldSet: @escaping (Record) -> Int, _ fields: [DatabaseRecordField<Record>]) {
		updates = DatabaseSqlFactory<Record>(tableName, getFieldSet, fields) {
			fieldSet, factory in
			return factory.createUpdate(fieldSet)
		}
		inserts = DatabaseSqlFactory<Record>(tableName, getFieldSet, fields) {
			fieldSet, factory in
			return factory.createInsert(fieldSet)
		}
		deletes = DatabaseSqlFactory<Record>(tableName, getFieldSet, fields) {
			fieldSet, factory in
			return factory.createDelete(fieldSet)
		}
	}
}



open class DatabaseRecordStatementFactory<Record> {
	let database: StorageDatabase
	open let updates: DatabaseStatementFactory<Record>
	open let inserts: DatabaseStatementFactory<Record>
	open let deletes: DatabaseStatementFactory<Record>

	public init(_ database: StorageDatabase, _ factory: DatabaseRecordSqlFactory<Record>) {
		self.database = database
		updates = DatabaseStatementFactory<Record>(database, factory.updates)
		inserts = DatabaseStatementFactory<Record>(database, factory.inserts)
		deletes = DatabaseStatementFactory<Record>(database, factory.deletes)
	}
}



extension StorageDatabase {
	public func iterateRecords<Record>(_ sql: String,
		record: Record,
		setParams: @escaping (DatabaseSelectStatement) -> Void,
		readRecord: @escaping (DatabaseReader, Record) -> Void) throws -> DatabaseRecordSequence<Record> {

		return DatabaseRecordSequence(database: self, sql: sql, record: record, setParams: setParams, readRecord: readRecord)
	}



	public func iterateValues<Value>(_ sql: String,
		setParams: @escaping (DatabaseSelectStatement) -> Void,
		readValue: @escaping (DatabaseReader) -> Value?) throws -> DatabaseValueSequence<Value> {

		return DatabaseValueSequence(database: self, sql: sql, setParams: setParams, readValue: readValue)
	}
}
