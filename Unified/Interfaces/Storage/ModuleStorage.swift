//
// Created by Michael Vlasov on 17.05.16.
//

import Foundation

public protocol ModuleStorage {
	func initializeDatabase(maintenance: DatabaseMaintenance) throws

	func getFileStoragePath(relativePath: String) -> String
	func readDatabase(read: (StorageDatabase) throws -> Void) throws
	func writeDatabase(write: (StorageDatabase) throws -> Void) throws
	func writeDatabaseWithoutTransaction(write: (StorageDatabase) throws -> Void) throws

}
