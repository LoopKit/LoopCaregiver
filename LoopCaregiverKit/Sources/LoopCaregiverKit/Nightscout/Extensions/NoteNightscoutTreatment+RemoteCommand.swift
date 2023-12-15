//
//  NoteNightscoutTreatment+RemoteCommand.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 8/7/23.
//

import Foundation
import NightscoutKit

public extension NoteNightscoutTreatment {
    func toRemoteCommand() -> RemoteCommand? {
        
        guard let noteText = notes else {
            return nil
        }

        guard let extractResult = extractAndParseErrorTextAndJSON(from: noteText) else {
            return nil
        }

        guard let remotePayload = try? extractResult.dictionary.toRemoteNotification() else {
            return nil
        }
        
        guard let sentAtDate = remotePayload.sentAt else {
            return nil
        }
        
        let error = RemoteCommandStatus.RemoteCommandStatusError(message: extractResult.leadingText)
        
        return RemoteCommand(id: remotePayload.id, action: remotePayload.toRemoteAction(), status: RemoteCommandStatus(state: .Error(error), message: extractResult.leadingText), createdDate: sentAtDate)
    }
    
    private func extractAndParseErrorTextAndJSON(from text: String) -> (leadingText: String, dictionary: [String: AnyObject])? {

        guard let rangeOfLastOpeningBrace = text.range(of: "{") else {
            return nil
        }
        
        var leadingText = String(text[text.startIndex..<rangeOfLastOpeningBrace.lowerBound])
        leadingText = removeErrorLeadingText(input: leadingText)

        // Extract the JSON string
        let jsonSubstring = text[rangeOfLastOpeningBrace.lowerBound..<text.endIndex]
        
        // Parse the JSON string
        let jsonData = Data(jsonSubstring.utf8)
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject] {
                return (leadingText, jsonObject)
            }
        } catch {
            print("Failed to parse JSON: \(error)")
        }

        return nil
    }
    
    private func removeErrorLeadingText(input: String) -> String {
        var toRet = input
        toRet = toRet.replacingOccurrences(of: "^\\s*Error:\\s*", with: "", options: .regularExpression)
        toRet = toRet.replacingOccurrences(of: "^\\s*Error\\s*", with: "", options: .regularExpression)
        return toRet
    }

}
