//
//  Persistence.swift
//  Test
//
//  Created by Bill Gestrich on 11/18/22.
//

import CoreData

class PersistenceController {
    
    
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer
    weak var delegate: PersistenceControllerDelegate?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LoopCaregiver")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        self.observeContext()
    }
    
    
    //MARK: Observation
    
    
    func observeContext() {

            let context = mainContext()
        let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        
        delegate?.persistentServiceDataUpdated(self)
//        guard let userInfo = notification.userInfo else { return }
//
//        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> where inserts.count > 0 {
//
//        }
//
//        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> where updates.count > 0 {
//
//        }
//
//        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> where deletes.count > 0 {
//
//        }
    }

    
    
    //MARK: Looper things - This should be moved.
    
    func addLooper(_ looper: Looper) {
        let context = mainContext()
        let looperCD = LooperCD(context: context)
        looperCD.name = looper.name
        looperCD.nightscoutURL = looper.nightscoutURL
        looperCD.nightscoutAPISecret = looper.apiSecret
        looperCD.otpURL = looper.otpURL
        looperCD.lastSelectedDate = looper.lastSelectedDate

        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func looperEntityName() -> String {
        return "LooperCD"
    }
    
    func mainContext() -> NSManagedObjectContext {
        return container.viewContext
    }
    
    func getLoopers() throws -> [Looper] {
        let context = mainContext()
        let fetchRequest = NSFetchRequest<LooperCD>(entityName: looperEntityName())
        
        return try context.fetch(fetchRequest).compactMap({$0.toLooper()})
    }
    
    func removeLooper(_ looper: Looper) throws {
        let context = mainContext()
        let fetchRequest = NSFetchRequest<LooperCD>(entityName: looperEntityName())
        fetchRequest.predicate = NSPredicate(
            format: "name == %@", looper.name //TODO: Use exact name match -- add a UUID to model.
        )

        let results = try context.fetch(fetchRequest)
        for result in results {
            context.delete(result)
        }
        try context.save()
    }
}



protocol PersistenceControllerDelegate: AnyObject {
    func persistentServiceDataUpdated(_ service:PersistenceController)
}

extension LooperCD {
    func toLooper() -> Looper? {
        guard let name = name,
                let nightscoutURL = nightscoutURL,
                let nightscoutAPISecret = nightscoutAPISecret,
                let otpURL = otpURL,
                let lastSelectedDate = lastSelectedDate
        else {
            return nil
        }
        return Looper(name: name, nightscoutURL: nightscoutURL, apiSecret: nightscoutAPISecret, otpURL: otpURL, lastSelectedDate: lastSelectedDate)
    }
}
