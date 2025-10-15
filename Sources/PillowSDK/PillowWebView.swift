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
    @Binding var webView: WKWebView?

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

        // Observe and prevent any contentOffset changes (prevents auto-scroll on focus)
        webView.scrollView.addObserver(
            context.coordinator,
            forKeyPath: "contentOffset",
            options: [.new],
            context: nil
        )

        // Set custom user agent if provided
        if let userAgent = userAgent {
            webView.customUserAgent = userAgent
        }

        // Store webView reference in coordinator for keyboard height updates
        context.coordinator.webView = webView

        // Pass webView reference back to parent
        DispatchQueue.main.async {
            self.webView = webView
        }

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

            // Inject keyboard height and dispatch event to webapp
            let transformValue = -height // Negative to move up
            let script = """
            document.documentElement.style.setProperty('--keyboard-height', '\(height)px');
            document.documentElement.style.setProperty('--keyboard-transform', '\(transformValue)px');
            console.log('[PillowSDK] Set keyboard height to \(height)px, transform to \(transformValue)px');

            // Dispatch keyboard change event to webapp so it can handle layout/scrolling
            (function() {
                const keyboardEvent = new MessageEvent('message', {
                    data: {
                        type: 'pillow:keyboardHeightChanged',
                        data: { height: \(height) }
                    },
                    origin: window.location.origin
                });
                window.dispatchEvent(keyboardEvent);
                console.log('[PillowSDK] Dispatched pillow:keyboardHeightChanged event with height:', \(height));
            })();
            """

            PillowLogger.debug("Injecting keyboard height: \(height)px, transform: \(transformValue)px")

            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    PillowLogger.error("Failed to execute keyboard script: \(error.localizedDescription)")
                } else {
                    PillowLogger.debug("Keyboard script executed successfully")
                }
            }
        }

        // Observe contentOffset changes to prevent auto-scroll
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            if keyPath == "contentOffset", let scrollView = object as? UIScrollView {
                // Force scroll position to stay at 0,0
                if scrollView.contentOffset.y != 0 || scrollView.contentOffset.x != 0 {
                    let offset = scrollView.contentOffset
                    PillowLogger.debug(
                        "Preventing auto-scroll: resetting contentOffset from \(offset) to (0,0)"
                    )
                    scrollView.contentOffset = .zero
                }
            }
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

        deinit {
            // Clean up observer
            webView?.scrollView.removeObserver(self, forKeyPath: "contentOffset")
        }
    }
}
#endif
