//
//  WatchConnectivityManager.swift
//  WeatherApp
//
//  Created by Bahalek on 2022-01-04.
//

import Foundation
import WatchConnectivity

public struct NotificationMessage: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let receivedDate: Date
}

public final class WatchConnectivityManager: NSObject, ObservableObject {
    @Published public var notificationMessage: NotificationMessage? = nil
    var pendingMessages = [String]()
    @Published public var lastMessageSent: Date? = nil
    @Published public var activated: Bool = false
    let watchSession: WCSession
    
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
#if os(iOS)
        guard watchSession.isWatchAppInstalled else {
            return
        }
#else
        guard watchSession.isCompanionAppInstalled else {
            return
        }
#endif
        do {
            try watchSession.updateApplicationContext([kMessageKey : message])
            lastMessageSent = Date()
        } catch {
            print("Cannot send message: \(String(describing: error))")
        }
//        watchSession.sendMessage([kMessageKey : message]) { error in
//            print("Cannot send message: \(String(describing: error))")
//        }
    }
    
    public func isReachable() -> Bool {
        return watchSession.isReachable
    }
    
    public func sessionsSupported() -> Bool {
        return WCSession.isSupported()
    }
    
#if os(watchOS)
    public func companionAppInstalled() -> Bool {
        return watchSession.isCompanionAppInstalled
    }
#endif
}

extension WatchConnectivityManager: WCSessionDelegate {
    
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
