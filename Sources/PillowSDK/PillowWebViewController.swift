//
//  PillowWebViewController.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

#if os(iOS)
import SwiftUI
import Combine
import WebKit

/// Modal view controller for the Pillow chat interface
internal struct PillowWebViewController: View {
    let url: URL
    let userAgent: String?

    @State private var keyboardHeight: CGFloat = 0
    @State private var webView: WKWebView?

    var body: some View {
        ZStack(alignment: .top) {
            PillowWebView(url: url, userAgent: userAgent, keyboardHeight: keyboardHeight, webView: $webView)
                .ignoresSafeArea(.all, edges: [.bottom])
                .onReceive(Publishers.keyboardHeight) { height in
                    PillowLogger.debug("Keyboard height changed to \(height)")
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.keyboardHeight = height
                    }
                    
                    // Inject transform value for GPU-accelerated positioning
                    if let webView = webView {
                        let transformValue = -height // Negative to move up
                        let script = """
                        document.documentElement.style.setProperty('--keyboard-transform', '\(transformValue)px');
                        console.log('[PillowSDK] Keyboard transform set to \(transformValue)px');
                        """
                        webView.evaluateJavaScript(script) { _, error in
                            if let error = error {
                                PillowLogger.error("Failed to inject keyboard transform: \(error)")
                            }
                        }
                    }
                }

            // Custom drag indicator that's always visible
            VStack(spacing: 0) {
                DragIndicator()
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                Spacer()
            }
            .allowsHitTesting(false) // Let touches pass through to webview
        }
        .presentationDragIndicator(.hidden) // Hide native indicator since we have custom one
    }
}

/// Custom drag indicator bar
private struct DragIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(UIColor.systemGray4))
            .frame(width: 36, height: 5)
    }
}

// Keyboard height publisher
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }

        return willShow.merge(with: willHide)
            .eraseToAnyPublisher()
    }
}
#endif
