//
//  DeepLinkHandlerPhone.swift
//
//
//  Created by Bill Gestrich on 2/26/24.
//

import Foundation

public protocol DeepLinkHandler {
    func handleDeepLinkURL(_ url: URL) async throws
}

public class DeepLinkHandlerPhone: DeepLinkHandler {
    
    let accountService: AccountServiceManager
    var settings: CaregiverSettings
    var watchService: WatchService
    
    public init(accountService: AccountServiceManager, settings: CaregiverSettings, watchService: WatchService) {
        self.accountService = accountService
        self.settings = settings
        self.watchService = watchService
    }
    
    @MainActor
    public func handleDeepLinkURL(_ url: URL) async throws {
        
        let deepLink = try DeepLinkParser().parseDeepLink(url: url)
        switch deepLink {
        case .addLooper(let createLooperDeepLink):
            try await handleAddLooperDeepLink(createLooperDeepLink)
        case .selectLooper(let selectLooperDeepLink):
            try await handleSelectLooperDeepLink(selectLooperDeepLink)
        case .requestWatchConfigurationDeepLink(let requestWatchConfigurationDeepLink):
            try await handleRequestWatchConfigurationDeepLink(requestWatchConfigurationDeepLink)
        }
    }
    
    @MainActor
    func handleSelectLooperDeepLink(_ deepLink: SelectLooperDeepLink) async throws {
        guard let looper = accountService.loopers.first(where: {$0.id == deepLink.looperUUID}) else {
            return
        }
        
        if accountService.selectedLooper != looper {
            accountService.selectedLooper = looper
        }
    }
    
    @MainActor
    func handleAddLooperDeepLink(_ deepLink: CreateLooperDeepLink) async throws {
        let looper = Looper(identifier: UUID(), name: deepLink.name, nightscoutCredentials: NightscoutCredentials(url: deepLink.nsURL, secretKey: deepLink.secretKey, otpURL: deepLink.otpURL.absoluteString), lastSelectedDate: Date())
        let service = accountService.createLooperService(looper: looper, settings: settings)
        try await service.remoteDataSource.checkAuth()

        if let existingLooper = accountService.loopers.first(where: {$0.name == looper.name}) {
            try accountService.removeLooper(existingLooper)
        }
        try accountService.addLooper(looper)
        try accountService.updateActiveLoopUser(looper)
    }
    
    @MainActor
    func handleRequestWatchConfigurationDeepLink(_ deepLink: RequestWatchConfigurationDeepLink) async throws {
        #if os(iOS)
        try watchService.sendLoopersToWatch()
        #else
        fatalError("Unexpected to be called on Watch")
        #endif
    }
}


public class DeepLinkHandlerWatch: DeepLinkHandler {
    
    let accountService: AccountServiceManager
    var settings: CaregiverSettings
    var watchService: WatchService
    
    public init(accountService: AccountServiceManager, settings: CaregiverSettings, watchService: WatchService) {
        self.accountService = accountService
        self.settings = settings
        self.watchService = watchService
    }
    
    @MainActor public func handleDeepLinkURL(_ url: URL) async throws {
        let deepLink = try DeepLinkParser().parseDeepLink(url: url)
        switch deepLink {
        case .addLooper(let createLooperDeepLink):
            try await handleAddLooperDeepLink(createLooperDeepLink)
        case .selectLooper(let selectLooperDeepLink):
            try await handleSelectLooperDeepLink(selectLooperDeepLink)
        case .requestWatchConfigurationDeepLink:
            assert(false, "Should not be received from iPhone")
        }
    }
    
    @MainActor
    func handleAddLooperDeepLink(_ deepLink: CreateLooperDeepLink) async throws {
        let looper = Looper(identifier: UUID(), name: deepLink.name, nightscoutCredentials: NightscoutCredentials(url: deepLink.nsURL, secretKey: deepLink.secretKey, otpURL: deepLink.otpURL.absoluteString), lastSelectedDate: Date())
        let service = accountService.createLooperService(looper: looper, settings: settings)
        try await service.remoteDataSource.checkAuth()

        if let existingLooper = accountService.loopers.first(where: {$0.name == looper.name}) {
            try accountService.removeLooper(existingLooper)
        }
        try accountService.addLooper(looper)
        try accountService.updateActiveLoopUser(looper)
        
    }
    
    @MainActor
    func handleSelectLooperDeepLink(_ deepLink: SelectLooperDeepLink) async throws {
        guard let looper = accountService.loopers.first(where: {$0.id == deepLink.looperUUID}) else {
            if accountService.loopers.isEmpty {
                do {
#if os(watchOS)
                    try watchService.requestWatchConfiguration()
#endif
                } catch {
                    print(error)
                }
                throw DeepLinkSelectLooperError.noLoopersOnWatch
            } else {
                throw DeepLinkSelectLooperError.invalidLoopersOnWatch
            }
        }
        
        if accountService.selectedLooper != looper {
            accountService.selectedLooper = looper
        }
    }
    
    enum DeepLinkSelectLooperError: LocalizedError {
        case noLoopersOnWatch
        case invalidLoopersOnWatch
        
        var errorDescription: String? {
            switch self {
            case .noLoopersOnWatch:
                return "No Loopers available on Watch. Open Caregiver Settings on your iPhone and tap 'Setup Watch'. Then remove this complication from your Watch face and add it again."
                
            case .invalidLoopersOnWatch:
                return "The selected complication is invalid. You must remove it from your Apple Watch face and add it again."
            }
        }
    }
}
