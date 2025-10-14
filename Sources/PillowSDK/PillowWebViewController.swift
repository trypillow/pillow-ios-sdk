//
//  PillowWebViewController.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

#if os(iOS)
import SwiftUI
import Combine

/// Modal view controller for the Pillow chat interface
internal struct PillowWebViewController: View {
    let url: URL
    let userAgent: String?

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        PillowWebView(url: url, userAgent: userAgent, keyboardHeight: keyboardHeight)
            .ignoresSafeArea(.all, edges: [.bottom])
            .onReceive(Publishers.keyboardHeight) { height in
                PillowLogger.debug("Keyboard height changed to \(height)")
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardHeight = height
                }
            }
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
