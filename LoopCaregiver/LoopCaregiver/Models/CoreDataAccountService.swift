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
        self.container = Self.createContainer(inMemory: inMemory)
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
    
    static func createContainer(inMemory: Bool) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "LoopCaregiver")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
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
