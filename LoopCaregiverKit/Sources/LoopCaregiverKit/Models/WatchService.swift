//
//  WatchService.swift
//
//
//  Created by Bill Gestrich on 2/9/24.
//

import Foundation

public class WatchService {
    let watchSession = WatchSession()
    let accountService: AccountService
    
    init(accountService: AccountService) {
        self.accountService = accountService
    }
}
