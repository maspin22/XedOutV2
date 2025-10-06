//
//  SafariWebExtensionHandler.swift
//  XedOutV2 Extension
//
//  Created by Michael Aspinwall on 3/10/25.
//

import SafariServices
import os.log
import Foundation

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        // Handle OpenAI API requests
        if let messageDict = message as? [String: Any],
           let action = messageDict["action"] as? String,
           action == "analyzeContent" {
            
            handleAnalyzeContent(messageDict: messageDict, context: context)
        } else {
            // Default echo response for other messages
            let response = NSExtensionItem()
            if #available(iOS 15.0, macOS 11.0, *) {
                response.userInfo = [ SFExtensionMessageKey: [ "echo": message ] ]
            } else {
                response.userInfo = [ "message": [ "echo": message ] ]
            }
            context.completeRequest(returningItems: [ response ], completionHandler: nil)
        }
    }
    
    private func handleAnalyzeContent(messageDict: [String: Any], context: NSExtensionContext) {
        guard let text = messageDict["text"] as? String,
              let apiKey = messageDict["apiKey"] as? String,
              let prompt = messageDict["prompt"] as? String else {
            os_log(.error, "Missing required parameters for analyzeContent")
            sendResponse(success: false, error: "Missing required parameters", context: context)
            return
        }
        
        let imageUrls = messageDict["imageUrls"] as? [String] ?? []
        
        // Make OpenAI API call
        Task {
            do {
                let result = try await callOpenAI(text: text, imageUrls: imageUrls, apiKey: apiKey, prompt: prompt)
                sendResponse(success: true, result: result, context: context)
            } catch {
                os_log(.error, "Error calling OpenAI API: %@", error.localizedDescription)
                sendResponse(success: false, error: error.localizedDescription, context: context)
            }
        }
    }
    
    private func callOpenAI(text: String, imageUrls: [String], apiKey: String, prompt: String) async throws -> Bool {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Build the prompt
        var fullPrompt = "\(prompt) Respond with only \"true\" or \"false\":\n"
        fullPrompt += "Post text: \"\(text)\"\n"
        
        if !imageUrls.isEmpty {
            fullPrompt += "The post contains \(imageUrls.count) image(s). Please consider the images in your analysis."
        }
        
        // Build messages array
        var contentArray: [[String: Any]] = [
            ["type": "text", "text": fullPrompt]
        ]
        
        // Add up to 2 images
        for imageUrl in imageUrls.prefix(2) {
            contentArray.append([
                "type": "image_url",
                "image_url": ["url": imageUrl]
            ])
        }
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": imageUrls.isEmpty ? fullPrompt : contentArray
            ]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SafariExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        os_log(.default, "OpenAI API response status: %d", httpResponse.statusCode)
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            os_log(.error, "OpenAI API error: %@", errorMessage)
            throw NSError(domain: "SafariExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            os_log(.error, "Invalid API response structure")
            throw NSError(domain: "SafariExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API response structure"])
        }
        
        let result = content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return result == "true"
    }
    
    private func sendResponse(success: Bool, result: Bool? = nil, error: String? = nil, context: NSExtensionContext) {
        let responseDict: [String: Any] = [
            "success": success,
            "result": result as Any,
            "error": error as Any
        ]
        
        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [ SFExtensionMessageKey: responseDict ]
        } else {
            response.userInfo = [ "message": responseDict ]
        }
        
        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }

}
