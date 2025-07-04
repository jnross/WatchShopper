import Foundation
import Logging
import os

class Logger {
    private let logger: Logging.Logger
    private let tag: String
    
    // Static property with lazy initialization - thread-safe and called only once
    private static let loggingSystemInitializer: Void = {
        // bootstrap must be called once and only once before any logging is done
        LoggingSystem.bootstrap { label in
            return SystemLogHandler(label: label)
        }
    }()
    
    init(tag: String) {
        self.tag = tag
        
        // Trigger the static initialization (only happens once)
        _ = Logger.loggingSystemInitializer
        
        self.logger = Logging.Logger(label: tag)
    }

    func log(_ message: String, level: Logging.Logger.Level = .info) {
        // Output using swift-log (which now goes to both Xcode debug console and Console app)
        logger.log(level: level, "\(message)")
    }

    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }

    func fault(_ message: String) {
        log(message, level: .critical)
    }
}

// Custom LogHandler that integrates with os_log for Console app visibility
struct SystemLogHandler: LogHandler {
    let label: String
    private let osLog: OSLog
    
    init(label: String) {
        self.label = label
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "WatchShopper", category: label)
    }
    
    var logLevel: Logging.Logger.Level = .debug
    
    func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let osLogType: OSLogType
        switch level {
        case .trace, .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .notice, .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .critical:
            osLogType = .fault
        }
        
        // Output to Console app via os_log (Also appears in modern Xcode versions)
        os_log("%{public}@", log: osLog, type: osLogType, message.description)
    }
    
    var metadata = Logging.Logger.Metadata()
    
    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
} 
