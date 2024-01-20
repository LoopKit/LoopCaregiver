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
}

public final class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()
    @Published public var notificationMessage: NotificationMessage? = nil
    var pendingMessages = [String]()
    @Published public var lastMessageSent: Date? = nil
    @Published public var activated: Bool = false
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private let kMessageKey = "message"
    
    public func send(_ message: String) {

        guard WCSession.default.activationState == .activated else {
            pendingMessages.append(message)
            return
        }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
#else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
#endif
        do {
            try WCSession.default.updateApplicationContext([kMessageKey : message])
            lastMessageSent = Date()
        } catch {
            print("Cannot send message: \(String(describing: error))")
        }
//        WCSession.default.sendMessage([kMessageKey : message]) { error in
//            print("Cannot send message: \(String(describing: error))")
//        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let notificationText = applicationContext[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.notificationMessage = NotificationMessage(text: notificationText)
            }
        }
    }
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let notificationText = message[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.notificationMessage = NotificationMessage(text: notificationText)
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
