//
//  PillowSDK.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
import WebKit
#endif

/// Main entry point for the Pillow SDK
public class PillowSDK {

    /// Shared singleton instance
    public static let shared = PillowSDK()

    /// SDK version
    public let version = "1.0.0"

    /// The configured Pillow chat URL
    private var pillowURL: URL?

    /// Current log level (default: .info)
    public var logLevel: PillowLogLevel = .info

    /// Banner auto-dismiss duration in seconds (default: 5.0)
    public var bannerDismissDelay: TimeInterval = 5.0

    /// Internal user agent for the webview
    private var userAgent: String {
        return "PillowSDK/\(version) (iOS)"
    }

    #if os(iOS)
    /// Persistent hosting controller - kept alive by SDK singleton
    private var hostingController: UIHostingController<PillowWebViewController>?

    /// Dismissal delegate to detect when modal is closed
    private lazy var dismissalDelegate = PresentationDismissalDelegate()

    /// Hidden window to keep WebView alive when chat is dismissed
    private var backgroundWindow: UIWindow?
    #endif

    /// Private initializer to enforce singleton pattern
    private init() {}

    /// Configures the SDK with the Pillow chat URL
    /// - Parameters:
    ///   - url: The URL for the Pillow chat interface
    ///   - logLevel: Logging level (default: .info)
    ///   - bannerDismissDelay: Auto-dismiss time for banners in seconds (default: 5.0)
    /// - Throws: Error if the URL is invalid
    public func configure(
        url: String,
        logLevel: PillowLogLevel = .info,
        bannerDismissDelay: TimeInterval = 5.0
    ) throws {
        guard let validURL = URL(string: url), validURL.scheme != nil else {
            throw PillowSDKError.invalidURL
        }
        self.pillowURL = validURL
        self.logLevel = logLevel
        self.bannerDismissDelay = bannerDismissDelay
        PillowLogger.info("SDK configured successfully")
    }

    /// Manually triggers a test message to verify the bridge is working
    /// This is useful for debugging - it simulates the webapp sending a message
    public func sendTestMessage() {
        #if os(iOS)
        guard let hostingController = hostingController,
              let webView = findWebView(in: hostingController.view) else {
            PillowLogger.error("Cannot send test message - webview not found")
            return
        }

        let script = """
        (function() {
            console.log('[PillowSDK] Sending test message from native...');
            const testMessage = {
                type: 'pillow:message',
                data: {
                    name: 'Test Sender',
                    message: 'This is a test message to verify the bridge works!',
                    avatar: null
                }
            };

            // Try both methods
            if (window.postMessage) {
                window.postMessage(testMessage, '*');
                console.log('[PillowSDK] Sent via window.postMessage');
            }
            if (window.parent.postMessage) {
                window.parent.postMessage(testMessage, '*');
                console.log('[PillowSDK] Sent via window.parent.postMessage');
            }
        })();
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                PillowLogger.error("Failed to send test message: \(error.localizedDescription)")
            } else {
                PillowLogger.info("Test message injected into webapp")
            }
        }
        #endif
    }

    /// Presents the Pillow chat interface in a full-screen modal
    /// - Parameters:
    ///   - scrollToBottom: Whether to scroll to the bottom after presenting (default: false)
    /// - Throws: Error if the SDK is not configured
    public func present(scrollToBottom: Bool = false) throws {
        #if os(iOS)
        guard let url = pillowURL else {
            throw PillowSDKError.notConfigured
        }

        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw PillowSDKError.noRootViewController
        }

        // Create hosting controller if it doesn't exist (SDK singleton keeps it alive)
        if hostingController == nil {
            PillowLogger.debug("Creating persistent webview controller")
            let webView = PillowWebViewController(url: url, userAgent: userAgent)
            hostingController = UIHostingController(rootView: webView)
            hostingController?.modalPresentationStyle = .pageSheet
        } else {
            PillowLogger.debug("Reusing existing webview controller")
        }

        // Configure sheet presentation (always, in case it was reset)
        if let sheet = hostingController?.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }

        guard let controller = hostingController else {
            throw PillowSDKError.notConfigured
        }
        
        // Set up dismissal detection
        controller.presentationController?.delegate = dismissalDelegate
        dismissalDelegate.onDismiss = { [weak self] in
            self?.handleDismissal()
        }

        // Move WebView back from background window if it was there
        moveWebViewToForeground()

        // Mark as presented
        NotificationManager.shared.isChatPresented = true
        PillowLogger.debug("Setting isChatPresented = true")

        // Present the controller
        rootViewController.present(controller, animated: true) { [weak self] in
            PillowLogger.info("Chat presented")

            // Notify webapp that chat is now visible (after animation completes)
            self?.notifyWebappOpened()

            // Scroll to bottom if requested
            if scrollToBottom {
                self?.scrollWebappToBottom()
            }
        }
        #else
        throw PillowSDKError.unsupportedPlatform
        #endif
    }

    #if os(iOS)
    private func handleDismissal() {
        NotificationManager.shared.isChatPresented = false
        PillowLogger.info("Chat dismissed")

        // Move WebView to hidden window to keep it alive and polling
        moveWebViewToBackgroundWindow()

        notifyWebappClosed()
    }

    private func moveWebViewToBackgroundWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            PillowLogger.error("No window scene available for background window")
            return
        }

        // Create hidden window if it doesn't exist
        if backgroundWindow == nil {
            let window = UIWindow(windowScene: windowScene)
            window.windowLevel = .normal - 1  // Below everything
            window.backgroundColor = .clear
            window.isHidden = false  // Must be visible for JS to run
            window.alpha = 0.01  // Nearly invisible but still "visible" to iOS
            window.frame = CGRect(x: 0, y: 0, width: 1, height: 1)  // Tiny size
            backgroundWindow = window
            PillowLogger.debug("Created background window for WebView")
        }

        // Move hosting controller to background window
        if let hostingController = hostingController {
            backgroundWindow?.rootViewController = hostingController
            backgroundWindow?.makeKeyAndVisible()
            // Restore key window status to main window
            if let mainWindow = windowScene.windows.first(where: { $0 != backgroundWindow }) {
                mainWindow.makeKey()
            }
            PillowLogger.debug("WebView moved to background window - JS will continue running")
        }
    }

    private func moveWebViewToForeground() {
        // Remove from background window
        backgroundWindow?.rootViewController = nil
        backgroundWindow?.isHidden = true
        PillowLogger.debug("WebView moved back to foreground")
    }

    private func notifyWebappOpened() {
        guard let hostingController = hostingController,
              let webView = findWebView(in: hostingController.view) else {
            return
        }

        let script = """
        (function() {
            const event = new MessageEvent('message', {
                data: { type: 'pillow:opened', data: {} },
                origin: window.location.origin
            });
            window.dispatchEvent(event);
            console.log('[PillowSDK] Sent pillow:opened to webapp');
        })();
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                PillowLogger.error("Failed to notify webapp opened: \(error.localizedDescription)")
            } else {
                PillowLogger.debug("Sent pillow:opened to webapp")
            }
        }
    }

    private func notifyWebappClosed() {
        guard let hostingController = hostingController,
              let webView = findWebView(in: hostingController.view) else {
            return
        }

        let script = """
        (function() {
            const event = new MessageEvent('message', {
                data: { type: 'pillow:closed', data: {} },
                origin: window.location.origin
            });
            window.dispatchEvent(event);
            console.log('[PillowSDK] Sent pillow:closed to webapp');
        })();
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                PillowLogger.error("Failed to notify webapp closed: \(error.localizedDescription)")
            } else {
                PillowLogger.debug("Sent pillow:closed to webapp")
            }
        }
    }

    private func scrollWebappToBottom() {
        guard let hostingController = hostingController,
              let webView = findWebView(in: hostingController.view) else {
            return
        }

        // Add delay to ensure webapp is ready after presentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let script = """
            (function() {
                const event = new MessageEvent('message', {
                    data: { type: 'pillow:scrollToBottom', data: {} },
                    origin: window.location.origin
                });
                window.dispatchEvent(event);
                console.log('[PillowSDK] Sent pillow:scrollToBottom to webapp');
            })();
            """

            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    PillowLogger.error("Failed to request scroll: \(error.localizedDescription)")
                } else {
                    PillowLogger.debug("Requested webapp to scroll to bottom")
                }
            }
        }
    }

    private func findWebView(in view: UIView) -> WKWebView? {
        if let webView = view as? WKWebView {
            return webView
        }
        for subview in view.subviews {
            if let webView = findWebView(in: subview) {
                return webView
            }
        }
        return nil
    }

    /// Delegate to detect modal dismissal
    private class PresentationDismissalDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
        var onDismiss: (() -> Void)?

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            onDismiss?()
        }
    }
    #endif
}
