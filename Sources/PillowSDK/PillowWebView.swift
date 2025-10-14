//
//  PillowWebView.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

#if os(iOS)
import SwiftUI
import WebKit

/// SwiftUI wrapper for WKWebView to display the Pillow chat interface
internal struct PillowWebView: UIViewRepresentable {
    let url: URL
    let userAgent: String?
    let keyboardHeight: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.lastKeyboardHeight = keyboardHeight
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        // Allow web content to be loaded (important for external images/resources)
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = false
        }

        // Add script message handler for webapp communication
        let contentController = configuration.userContentController
        contentController.add(context.coordinator.webAppBridge, name: "pillowMessageHandler")

        // Add message interceptor script (must be added BEFORE loading the page)
        contentController.addUserScript(WebAppBridge.createInterceptorScript())

        let webView = NoAccessoryWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .clear

        // Enable Web Inspector (Safari Develop menu)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // CRITICAL: Disable WebView's own scrolling - content handles it internally
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        // Allow interactive keyboard dismissal
        webView.scrollView.keyboardDismissMode = .interactive

        // Set custom user agent if provided
        if let userAgent = userAgent {
            webView.customUserAgent = userAgent
        }

        // Store webView reference in coordinator for keyboard height updates
        context.coordinator.webView = webView

        // Load the URL
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only inject keyboard height if it has changed to avoid disrupting input focus
        if context.coordinator.lastKeyboardHeight != keyboardHeight {
            context.coordinator.lastKeyboardHeight = keyboardHeight
            context.coordinator.updateKeyboardHeight(keyboardHeight)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastKeyboardHeight: CGFloat = 0
        weak var webView: WKWebView?
        let webAppBridge = WebAppBridge()

        func updateKeyboardHeight(_ height: CGFloat) {
            guard let webView = webView else { return }

            // Simple: just set the CSS variable, let CSS handle everything
            let script = "document.documentElement.style.setProperty('--keyboard-height', '\(height)px');"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            PillowLogger.debug("WebView started loading")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            PillowLogger.debug("WebView finished loading")
            // Inject initial keyboard height after page loads
            updateKeyboardHeight(lastKeyboardHeight)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            PillowLogger.error("WebView failed to load: \(error.localizedDescription)")
        }
    }
}
#endif
