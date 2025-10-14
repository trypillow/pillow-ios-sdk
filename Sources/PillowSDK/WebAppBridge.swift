//
//  WebAppBridge.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

#if os(iOS)
import Foundation
import WebKit

/// Handles communication between the webapp and native iOS SDK
internal class WebAppBridge: NSObject, WKScriptMessageHandler {

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "pillowMessageHandler" else {
            PillowLogger.debug("Unexpected message handler name: \(message.name)")
            return
        }

        PillowLogger.debug("Received message from webapp - raw body type: \(type(of: message.body))")

        // Parse message from webapp
        if let body = message.body as? [String: Any] {
            PillowLogger.debug("Successfully parsed body as dictionary with keys: \(body.keys.joined(separator: ", "))")

            if let type = body["type"] as? String {
                PillowLogger.debug("Message type: \(type)")

                switch type {
                case "pillow:message":
                    PillowLogger.debug("Handling pillow:message event")
                    PillowLogger.debug("isChatPresented status: \(NotificationManager.shared.isChatPresented)")
                    handleIncomingMessage(body["data"] as? [String: Any])
                case "pillow:ready":
                    handleReady(body["data"] as? [String: Any])
                case "pillow:notification":
                    handleNotification(body["data"] as? [String: Any])
                default:
                    PillowLogger.debug("Unhandled message type: \(type)")
                }
            } else {
                PillowLogger.debug("No type field in message. Body keys: \(body.keys.joined(separator: ", "))")
            }
        } else {
            PillowLogger.debug("Failed to parse message body. Raw body: \(message.body)")
        }
    }

    // MARK: - Private Methods

    private func handleIncomingMessage(_ data: [String: Any]?) {
        guard let data = data else {
            PillowLogger.debug("No data in pillow:message")
            return
        }

        let messageText = data["message"] as? String ?? ""
        let senderName = data["name"] as? String
        let avatarURL = data["avatar"] as? String

        PillowLogger.info(
            "Received message preview - name: \(senderName ?? "nil"), message length: \(messageText.count)"
        )

        // Show banner notification
        NotificationManager.shared.showBanner(
            senderName: senderName ?? "New message",
            avatarURL: avatarURL,
            messagePreview: messageText
        )

        PillowLogger.debug("Banner notification triggered")
    }

    private func handleReady(_ data: [String: Any]?) {
        let isFirstVisit = data?["isFirstVisit"] as? Bool ?? false
        PillowLogger.info("Webapp ready - first visit: \(isFirstVisit)")
    }

    private func handleNotification(_ data: [String: Any]?) {
        let count = data?["count"] as? Int ?? 0
        PillowLogger.info("Badge notification - unread count: \(count)")
        // Future: Could update app badge here
    }

    // MARK: - JavaScript Injection

    /// Creates a WKUserScript to intercept postMessage calls from webapp
    /// This must be added to WKUserContentController BEFORE loading the page
    static func createInterceptorScript() -> WKUserScript {
        let source = """
        (function() {
            console.log('[PillowSDK] Injecting message interceptor at document start...');

            // Helper function to forward messages to native
            function forwardToNative(message) {
                if (window.webkit?.messageHandlers?.pillowMessageHandler) {
                    console.log('[PillowSDK] Forwarding message to native:', message);
                    try {
                        window.webkit.messageHandlers.pillowMessageHandler.postMessage(message);
                    } catch (err) {
                        console.error('[PillowSDK] Error forwarding to native:', err);
                    }
                } else {
                    console.error('[PillowSDK] Native message handler not available');
                }
            }

            // Intercept window.postMessage
            const originalWindowPostMessage = window.postMessage.bind(window);
            window.postMessage = function(message, targetOrigin) {
                forwardToNative(message);
                return originalWindowPostMessage(message, targetOrigin);
            };

            // Intercept window.parent.postMessage (in case webapp is in iframe context)
            if (window.parent && window.parent !== window) {
                const originalParentPostMessage = window.parent.postMessage.bind(window.parent);
                window.parent.postMessage = function(message, targetOrigin) {
                    forwardToNative(message);
                    return originalParentPostMessage(message, targetOrigin);
                };
            }

            console.log('[PillowSDK] Message interceptor installed');
        })();
        """

        return WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }
}
#endif
