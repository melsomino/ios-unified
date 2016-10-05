//
// Created by Michael Vlasov on 17.05.16.
//

import Foundation

public protocol ModuleStorage {
	func initializeDatabase(_ maintenance: DatabaseMaintenance) throws

	func getFileStoragePath(_ relativePath: String) -> String
	func readDatabase(_ read: (StorageDatabase) throws -> Void) throws
	func writeDatabase(_ write: (StorageDatabase) throws -> Void) throws
	func writeDatabaseWithoutTransaction(_ write: (StorageDatabase) throws -> Void) throws

}
