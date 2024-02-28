//
//  ServiceComposer.swift
//
//
//  Created by Bill Gestrich on 1/17/24.
//

import Foundation

public protocol ServiceComposer {
    var settings: CaregiverSettings {get}
    var accountServiceManager: AccountServiceManager {get}
    var deepLinkHandler: DeepLinkHandler {get}
    var watchService: WatchService {get}
}
