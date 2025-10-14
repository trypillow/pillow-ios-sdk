//
//  NoAccessoryWebView.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

#if os(iOS)
import WebKit

/// Custom WKWebView that removes the iOS accessory bar (QuickType)
internal class NoAccessoryWebView: WKWebView {
    override var inputAccessoryView: UIView? {
        return nil
    }
}
#endif
