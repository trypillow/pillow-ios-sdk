//
//  Logger.swift
//  PillowSDK
//
//  Created by Clément Raffenoux on 14/10/2025.
//

import Foundation

/// Log levels for PillowSDK
public enum PillowLogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case error = 2
    case none = 3

    public static func < (lhs: PillowLogLevel, rhs: PillowLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Internal logger for PillowSDK
internal struct PillowLogger {

    /// Log a debug message (most verbose - shows file and line)
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        guard PillowSDK.shared.logLevel <= .debug else { return }
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        print("[PillowSDK] [Debug] [\(fileName):\(line)] \(message)")
    }

    /// Log an info message (default level)
    static func info(_ message: String) {
        guard PillowSDK.shared.logLevel <= .info else { return }
        print("[PillowSDK] [Info] \(message)")
    }

    /// Log an error message (always shown unless .none)
    static func error(_ message: String) {
        guard PillowSDK.shared.logLevel <= .error else { return }
        print("[PillowSDK] [Error] \(message)")
    }
}
