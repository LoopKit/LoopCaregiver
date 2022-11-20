//
//  AccountKeychainService.swift
//
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation

class KeychainService {
    
    let securityDomain = "org.gestrich"
    weak var delegate: AccountKeychainServiceDelegate?
        
    init(){

    }
    
    func getKeyChainItems() throws -> [KeychainItem] {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecMatchLimit as String: kSecMatchLimitAll,
                                    kSecReturnAttributes as String: true,
                                    //Can't query on kSecAttrServer since we don't own the server (a NS URL).
                                    //So we use the securityDomain although it doesn't have meaning to us here
                                    //other than as a tag to save/retrieve the same item.
//                                    kSecAttrSecurityDomain as String: securityDomain,
                                    kSecReturnData as String: true]
        
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        guard status != errSecItemNotFound else {
            return []
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let rawItems = items as? [[String: Any]] else {
            throw KeychainError.unexpectedItemData
        }
        
        var keychainItems = [KeychainItem]()
        for item in rawItems {
            let account = try itemFromKeychainDictionary(item)
            keychainItems.append(account)
        }
        
        return keychainItems

    }
    
    func itemFromKeychainDictionary(_ itemDictionary: [String: Any]) throws -> KeychainItem {
        
        guard let server = itemDictionary[kSecAttrServer as String] as? String else {
            throw KeychainError.unexpectedServerData
        }
        
        guard let account = itemDictionary[kSecAttrAccount as String] as? String else {
            throw KeychainError.unexpectedAccountData
        }
        
        guard let secretValueData = itemDictionary[kSecValueData as String] as? Data else {
            throw KeychainError.unexpectedPasswordData
        }
        
        guard let secretValue = String(data: secretValueData, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return KeychainItem(account: account, server: server, value: secretValue)
    }
        
    func saveItem(_ item: KeychainItem) throws {
        let valueData = item.value.data(using: String.Encoding.utf8)!
        let saveQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                        kSecAttrAccount as String: item.account,
                                        kSecAttrServer as String: item.server,
                                        kSecAttrSecurityDomain as String: securityDomain,
                                        kSecValueData as String: valueData]
        
        SecItemDelete(saveQuery as CFDictionary)
        let status = SecItemAdd(saveQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        delegate?.keychainServiceDataUpdated(self)
    }
    
    func deleteItem(_ item: KeychainItem) throws {
        
        let deleteQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                          kSecAttrServer as String: item.server,
        ]
        
        SecItemDelete(deleteQuery as CFDictionary)
        
        delegate?.keychainServiceDataUpdated(self)
    }

    
    enum KeychainError: Error {
        case notSaved
        case unexpectedItemData
        case unexpectedServerData
        case unexpectedAccountData
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }
    
}

struct KeychainItem {
    let account: String
    let server: String
    let value: String
}

protocol AccountKeychainServiceDelegate: AnyObject {
    func keychainServiceDataUpdated(_ service:KeychainService)
}


//MARK: Looper to Keychain bridge

extension KeychainService {
    func getLoopers() throws -> [Looper] {
        return try getKeyChainItems().map({$0.toLooper()})
    }
    
    func addLooper(_ looper: Looper) throws {
        try saveItem(looper.toKeychainItem())
    }
    
    func removeLooper(_ looper: Looper) throws {
        try deleteItem(looper.toKeychainItem())
    }
}

extension Looper {
    func toKeychainItem() -> KeychainItem {
        return KeychainItem(account: name, server: nightscoutURL, value: apiSecret)
    }
}

extension KeychainItem {
    func toLooper() -> Looper {
        //TODO: Remove this
        return Looper(name: account, nightscoutURL: server, apiSecret: value, otpURL: "", lastSelectedDate: Date())
    }
}
