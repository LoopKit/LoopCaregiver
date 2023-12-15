//
//  RemoteNotification.swift
//  NightscoutUploadKit
//
//  Created by Bill Gestrich on 2/25/23.
//  Copyright © 2023 Pete Schwamb. All rights reserved.
//

import Foundation

public protocol RemoteNotification: Codable {
    
    var id: String {get}
    var expiration: Date? {get}
    var sentAt: Date? {get}
    var remoteAddress: String {get}
    var enteredBy: String? {get}
    
    func toRemoteAction() -> Action
    
    static func includedInNotification(_ notification: [String: Any]) -> Bool
}

extension RemoteNotification {
    
    public var id: String {
        //There is no unique identifier so we use the sent date when available
        if let sentAt = sentAt {
            return "\(sentAt.timeIntervalSince1970)"
        } else {
            return UUID().uuidString
        }
    }
    
    init(dictionary: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601DateDecoder)
        self = try jsonDecoder.decode(Self.self, from: data)
    }
}

extension DateFormatter {
    static var iso8601DateDecoder: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" //Ex: 2022-12-24T21:34:02.090Z
        return formatter
    }()
}

extension Dictionary<String, AnyObject> {
    
    public enum RemoteNotificationError: LocalizedError {
        case unhandledNotification([String: AnyObject])
        
        public var errorDescription: String? {
            switch self {
            case .unhandledNotification(let notification):
                return String(format: NSLocalizedString("Unhandled Notification: %1$@", comment: "The prefix for the remote unhandled notification error. (1: notification payload)"), notification)
            }
        }
    }
    
    public func toRemoteNotification() throws -> RemoteNotification {
        if BolusRemoteNotification.includedInNotification(self) {
            return try BolusRemoteNotification(dictionary: self)
        } else if CarbRemoteNotification.includedInNotification(self) {
            return try CarbRemoteNotification(dictionary: self)
        }  else if OverrideRemoteNotification.includedInNotification(self) {
            return try OverrideRemoteNotification(dictionary: self)
        } else if OverrideCancelRemoteNotification.includedInNotification(self) {
            return try OverrideCancelRemoteNotification(dictionary: self)
        } else {
            throw RemoteNotificationError.unhandledNotification(self)
        }
    }
}
