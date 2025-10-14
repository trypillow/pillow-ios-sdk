//
//  NotificationManager.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

#if os(iOS)
import UIKit
import SwiftUI

/// Manages banner notifications for the SDK
internal class NotificationManager {

    /// Singleton instance
    static let shared = NotificationManager()

    /// Banner window for displaying notifications
    private var bannerWindow: UIWindow?

    /// Track if chat is currently presented (set by PillowSDK)
    var isChatPresented: Bool = false

    private init() {}

    /// Shows a message notification banner at the top of the screen
    /// - Parameters:
    ///   - senderName: The name of the message sender
    ///   - avatarURL: Optional URL for the sender's avatar
    ///   - messagePreview: Preview text of the message
    func showBanner(
        senderName: String,
        avatarURL: String? = nil,
        messagePreview: String
    ) {
        PillowLogger.debug("showBanner called - isChatPresented: \(isChatPresented)")

        // Don't show banner if chat is currently open
        guard !isChatPresented else {
            PillowLogger.debug("Skipping banner - chat is open")
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            PillowLogger.error("No window scene available for banner")
            return
        }

        // Create or reuse banner window
        if bannerWindow == nil {
            let window = UIWindow(windowScene: windowScene)
            window.windowLevel = .alert + 1
            window.backgroundColor = .clear
            window.isUserInteractionEnabled = true
            bannerWindow = window
        }

        let notification = MessageNotification(
            senderName: senderName,
            avatarURL: avatarURL,
            messagePreview: messagePreview
        )

        let bannerView = BannerHostingView(
            notification: notification,
            onTap: {
                PillowLogger.info("Message banner tapped")
                do {
                    try PillowSDK.shared.present(scrollToBottom: true)
                } catch {
                    PillowLogger.error("Failed to present chat: \(error.localizedDescription)")
                }
            },
            onDismiss: {
                NotificationManager.shared.hideBanner()
            }
        )

        let hostingController = UIHostingController(rootView: bannerView)
        hostingController.view.backgroundColor = .clear

        bannerWindow?.rootViewController = hostingController
        bannerWindow?.isHidden = false

        PillowLogger.info("Message banner displayed")

        // Auto-dismiss after configured delay
        let dismissDelay = PillowSDK.shared.bannerDismissDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            NotificationManager.shared.hideBanner()
        }
    }

    private func hideBanner() {
        UIView.animate(withDuration: 0.3, animations: {
            self.bannerWindow?.alpha = 0
        }, completion: { _ in
            self.bannerWindow?.isHidden = true
            self.bannerWindow?.rootViewController = nil
            self.bannerWindow?.alpha = 1
        })
    }
}
#endif
