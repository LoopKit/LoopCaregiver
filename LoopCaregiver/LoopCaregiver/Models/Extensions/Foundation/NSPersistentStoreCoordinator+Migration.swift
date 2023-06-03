//
//  NSPersistentStoreCoordinator+Migration.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 6/3/23.
//

import Foundation
import CoreData

extension NSPersistentStoreCoordinator {
    func migrateAndDeleteStore(_ store: NSPersistentStore, atURL: URL, toURL: URL) {
            do {
                try migratePersistentStore(store, to: toURL, options: nil, withType: NSSQLiteStoreType)
            } catch {
                print(error.localizedDescription)
            }

            // delete old store
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            fileCoordinator.coordinate(writingItemAt: atURL, options: .forDeleting, error: nil, byAccessor: { url in
                do {
                    try FileManager.default.removeItem(at: atURL)
                } catch {
                    print(error.localizedDescription)
                }
            })
        }
}
