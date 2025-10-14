//
//  PillowSDKError.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

import Foundation

/// Errors that can be thrown by the Pillow SDK
public enum PillowSDKError: Error, LocalizedError {
    case invalidURL
    case notConfigured
    case noRootViewController
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .notConfigured:
            return "PillowSDK must be configured before presenting"
        case .noRootViewController:
            return "No root view controller found"
        case .unsupportedPlatform:
            return "This feature is only available on iOS"
        }
    }
}
