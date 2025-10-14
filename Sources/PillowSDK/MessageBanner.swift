//
//  MessageBanner.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

import SwiftUI

/// Model representing a message to display in the banner
public struct MessageNotification: Identifiable {
    public let id = UUID()
    public let senderName: String
    public let avatarURL: String?
    public let messagePreview: String
    public let timestamp: Date

    public init(
        senderName: String,
        avatarURL: String? = nil,
        messagePreview: String,
        timestamp: Date = Date()
    ) {
        self.senderName = senderName
        self.avatarURL = avatarURL
        self.messagePreview = messagePreview
        self.timestamp = timestamp
    }
}

/// A banner view that displays a message notification
public struct MessageBanner: View {
    let notification: MessageNotification
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    public init(
        notification: MessageNotification,
        onTap: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.notification = notification
        self.onTap = onTap
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                if let avatarURL = notification.avatarURL, !avatarURL.isEmpty {
                    AsyncImage(url: URL(string: avatarURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            avatarPlaceholder
                        @unknown default:
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .transaction { transaction in
                        transaction.animation = nil  // Disable AsyncImage fade animation
                    }
                } else {
                    avatarPlaceholder
                }
            }

            // Message content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.senderName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(notification.messagePreview)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 5)
        )
        .offset(y: dragOffset)
        .opacity(isDragging ? 0.95 : 1.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow upward drag (negative translation)
                    if value.translation.height < 0 {
                        isDragging = true
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    isDragging = false
                    // If dragged up more than 50 points, dismiss
                    if value.translation.height < -50 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = -200
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        // Spring back to original position
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            if !isDragging {
                onTap()
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay {
                Text(notification.senderName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
    }
}

#if os(iOS)
/// SwiftUI view that hosts the banner with animation for window-based presentation
internal struct BannerHostingView: View {
    let notification: MessageNotification
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var isShowing = false

    var body: some View {
        VStack(spacing: 0) {
            MessageBanner(
                notification: notification,
                onTap: {
                    onTap()
                    dismissBanner()
                },
                onDismiss: {
                    dismissBanner()
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .offset(y: isShowing ? 0 : -150)
            .opacity(isShowing ? 1 : 0)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isShowing = true
            }
        }
    }

    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
#endif

/// A view modifier that displays a message banner with animation
public struct MessageBannerModifier: ViewModifier {
    @Binding var notification: MessageNotification?
    let onTap: () -> Void
    let autoDismissAfter: TimeInterval?

    @State private var isShowing = false

    public init(
        notification: Binding<MessageNotification?>,
        onTap: @escaping () -> Void,
        autoDismissAfter: TimeInterval? = 5.0
    ) {
        self._notification = notification
        self.onTap = onTap
        self.autoDismissAfter = autoDismissAfter
    }

    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let notification = notification {
                MessageBanner(
                    notification: notification,
                    onTap: {
                        onTap()
                        dismissBanner()
                    },
                    onDismiss: {
                        dismissBanner()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .offset(y: isShowing ? 0 : -150)
                .opacity(isShowing ? 1 : 0)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isShowing = true
                    }

                    // Auto-dismiss after delay if configured
                    if let dismissDelay = autoDismissAfter {
                        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                            dismissBanner()
                        }
                    }
                }
            }
        }
    }

    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            notification = nil
        }
    }
}

extension View {
    /// Displays a message notification banner
    /// - Parameters:
    ///   - notification: Binding to the notification to display (nil to hide)
    ///   - onTap: Action to perform when banner is tapped
    ///   - autoDismissAfter: Time in seconds before auto-dismissing (nil to disable)
    public func messageBanner(
        notification: Binding<MessageNotification?>,
        onTap: @escaping () -> Void = {},
        autoDismissAfter: TimeInterval? = 5.0
    ) -> some View {
        self.modifier(
            MessageBannerModifier(
                notification: notification,
                onTap: onTap,
                autoDismissAfter: autoDismissAfter
            )
        )
    }
}
