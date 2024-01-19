//
//  IntentHandler.swift
//  LoopCaregiverIntentsExtension
//
//  Created by Bill Gestrich on 6/5/23.
//

import Intents
import LoopCaregiverKit

class IntentHandler: INExtension {
    
    var accountServiceManager: AccountServiceManager {
        let composer = ServiceComposerProduction()
        return AccountServiceManager(accountService: composer.accountServiceManager)
    }
    
    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
}

extension IntentHandler: ConfigurationIntentHandling {
     
    func defaultLooper(for intent: ConfigurationIntent) -> SelectedLooper? {
        guard let selectedLooper = accountServiceManager.selectedLooper else {
            return nil
        }

        return .init(identifier: selectedLooper.id, display: selectedLooper.name)
    }

    func provideLooperOptionsCollection(for intent: ConfigurationIntent) async throws -> INObjectCollection<SelectedLooper> {
        let loopers = try accountServiceManager.getLoopers().sorted(by: {$0.name.caseInsensitiveCompare($1.name) == .orderedAscending})
        return INObjectCollection(items: loopers.map({.init(identifier: $0.id, display: $0.name)}))
    }
}
