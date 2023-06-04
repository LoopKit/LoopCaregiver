//
//  CoreDataAccountService.swift
//  Test
//
//  Created by Bill Gestrich on 11/18/22.
//

import CoreData

class CoreDataAccountService: AccountService {
    
    let container: NSPersistentContainer
    weak var delegate: AccountServiceDelegate?
    
    init(inMemory: Bool = false) {
        if inMemory {
            self.container = Self.createInMemoryContainer()
        } else {
            self.container = Self.createContainer()
        }

        self.observeContext()
    }
    
    
    //MARK: API
    
    func addLooper(_ looper: Looper) throws {
        let context = mainContext()
        let looperCD = LooperCD(context: context)
        looperCD.name = looper.name
        looperCD.nightscoutURL = looper.nightscoutCredentials.url.absoluteString
        looperCD.nightscoutAPISecret = looper.nightscoutCredentials.secretKey
        looperCD.otpURL = looper.nightscoutCredentials.otpURL
        looperCD.lastSelectedDate = looper.lastSelectedDate
        try context.save()
    }
    
    func fetchLooperCD(name: String) throws -> LooperCD? {
        let context = mainContext()
        let fetchRequest = NSFetchRequest<LooperCD>(entityName: looperEntityName())
        fetchRequest.predicate = NSPredicate(
            format: "name == %@", name //TODO: Use exact name match -- add a UUID to model.
        )
        
        let results = try context.fetch(fetchRequest)
        assert(results.count <= 1)
        
        guard let looperCD = results.first else {
            return nil
        }
        
        return looperCD
    }
    
    func updateActiveLoopUser(_ looper: Looper) throws {
        let context = mainContext()
        guard let looperCD = try fetchLooperCD(name: looper.name) else {
            throw LooperPersistenceError.updateError
        }
        
        looperCD.lastSelectedDate = Date()
        try context.save()
        
        guard try fetchLooperCD(name: looper.name)?.toLooper() != nil else {
            throw LooperPersistenceError.updateError
        }
    }
    
    func looperEntityName() -> String {
        return "LooperCD"
    }
    
    func getLoopers() throws -> [Looper] {
        let context = mainContext()
        let fetchRequest = NSFetchRequest<LooperCD>(entityName: looperEntityName())
        return try context.fetch(fetchRequest).compactMap({$0.toLooper()})
    }
    
    func removeLooper(_ looper: Looper) throws {
        guard let looperCD = try fetchLooperCD(name: looper.name) else {
            throw LooperPersistenceError.deleteError
        }
        
        let context = mainContext()
        context.delete(looperCD)
        try context.save()
    }
    
    enum LooperPersistenceError: LocalizedError {
        case fetchError
        case updateError
        case deleteError
    }
    
    
    //MARK: Observation
    
    func observeContext() {
        let context = mainContext()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        delegate?.accountServiceDataUpdated(self)
    }
    
    
    //MARK: Util
    
    func mainContext() -> NSManagedObjectContext {
        return container.viewContext
    }
    
    
    //MARK: NSPersistentContainer Creation
    
    static func createContainer() -> NSPersistentContainer {
        
        switch getStoreMigrationStatus() {
        case .notRequired:
            let container = NSPersistentContainer(name: storeFileName)
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
            container.loadPersistentStores(completionHandler: { (_, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            
            container.viewContext.automaticallyMergesChangesFromParent = true
            return container
        case .required(let legacyDefaultStoreURL):
            let container = NSPersistentContainer(name: storeFileName)
            container.loadPersistentStores(completionHandler: { (_, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
                
                guard let legacyStore = container.persistentStoreCoordinator.persistentStore(for: legacyDefaultStoreURL) else {
                    fatalError("Could not load legacy store for migration")
                }
                
                container.persistentStoreCoordinator.migrateAndDeleteStore(legacyStore, atURL: legacyDefaultStoreURL, toURL: storeURL)
            })
            
            container.viewContext.automaticallyMergesChangesFromParent = true
            return container
        }
    }
    
    static var appGroup: String {
        return Bundle.main.appGroupSuiteName
    }
    
    static var storeURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!.appendingPathComponent(storeFileName.appending(".sqlite"))
    }
    
    static func createInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: storeFileName)
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }
    
    static func getStoreMigrationStatus() -> StoreMigrationStatus {
        
        let container = NSPersistentContainer(name: storeFileName)
        
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            return .notRequired
        }
        
        guard let legacyDefaultStoreURL = storeDescription.url else {
            return .notRequired
        }
        
        guard FileManager.default.fileExists(atPath: legacyDefaultStoreURL.path) else {
            return .notRequired
        }
        
        return .required(legacyDefaultStoreURL: legacyDefaultStoreURL)
    }
    
    static var storeFileName: String {
        return "LoopCaregiver"
    }
    
    enum StoreMigrationStatus {
        case required(legacyDefaultStoreURL: URL)
        case notRequired
    }
    
    
    //MARK: Previews
    
    static var preview: CoreDataAccountService = {
        let result = CoreDataAccountService(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

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
        
        //TODO: Remove force cast
        return Looper(name: name, nightscoutCredentials: NightscoutCredentials(url: URL(string: nightscoutURL)!, secretKey: nightscoutAPISecret, otpURL: otpURL), lastSelectedDate: lastSelectedDate)
    }
}
