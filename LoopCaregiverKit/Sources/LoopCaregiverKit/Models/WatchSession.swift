//
//  WatchSession.swift
//
//
//  Created by Bill Gestrich on 2/9/24.
//

import Foundation
import WatchConnectivity

public struct NotificationMessage: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let receivedDate: Date
}

public final class WatchSession: NSObject, ObservableObject {
    
    @Published public var notificationMessage: NotificationMessage? = nil
    @Published public var lastMessageSent: Date? = nil
    @Published public var activated: Bool = false
    private var pendingMessages = [String]()
    private let watchSession: WCSession
    
    public override init() {
        self.watchSession = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            watchSession.delegate = self
            watchSession.activate()
        }
    }
    
    private let kMessageKey = "message"
    
    public func send(_ message: String) {

        guard watchSession.activationState == .activated else {
            pendingMessages.append(message)
            return
        }

        guard isCounterpartAppInstalled() else {
            return
        }

        do {
            try watchSession.updateApplicationContext([kMessageKey : message])
            lastMessageSent = Date()
        } catch {
            print("Cannot send message: \(String(describing: error))")
        }
    }
    
    public func isReachable() -> Bool {
        return watchSession.isReachable && activated
    }
    
    public func sessionsSupported() -> Bool {
        return WCSession.isSupported()
    }
    
    public func isCounterpartAppInstalled() -> Bool {
#if os(iOS)
        return watchSession.isWatchAppInstalled
#else
        return watchSession.isCompanionAppInstalled
#endif
    }
}

extension WatchSession: WCSessionDelegate {
    
    //Each context message must be unique or it will be dropped. https://stackoverflow.com/a/47915741
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let notificationText = applicationContext[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.notificationMessage = NotificationMessage(text: notificationText, receivedDate: Date())
            }
        }
    }
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let notificationText = message[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.notificationMessage = NotificationMessage(text: notificationText, receivedDate: Date())
            }
        }
    }
    
    public func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error {
            print("WCSession activation error: \(error)")
        } else {
            DispatchQueue.main.async {
                
                if activationState == .activated {
                    self.activated = true
                }
                
                for message in self.pendingMessages {
                    self.send(message)
                }
            }
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

public extension WCSessionActivationState {
    func description() -> String {
        switch self {
        case .notActivated:
            return "Not Activated"
        case .inactive:
            return "Inactive"
        case .activated:
            return "Activated"
        @unknown default:
            return "Unknown"
        }
    }
}
