//
//  Log.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import OSLog

/// A singleton class that provides logging functionality throughout the application.
/// Utilizes Apple's unified logging system via the `Logger` class.
/// Inherits from `NSObject`.
class Log: NSObject {
    // MARK: - Properties

    /// The shared singleton instance of `Log`.
    static let shared = Log()
    
    /// The subsystem identifier, typically set to the app's bundle identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// The `Logger` instance used for logging messages.
    private let logger = Logger(subsystem: subsystem, category: "WeatherApp")
    
    // MARK: - Initializer
    
    /// Private initializer to prevent external instantiation.
    private override init() {
        // This initializer is intentionally left empty because this class follows a singleton pattern,
        // and no setup is required during initialization.
        // The instance is created only once, and the class provides globally accessible shared resources.
        // Any necessary setup can be done lazily when required.
    }
    
    // MARK: - Logging Methods
    
    /// Logs a message with additional contextual information such as file name, function name, and line number.
    ///
    /// - Parameters:
    ///   - message: The message or object to be logged. Defaults to an empty string.
    ///   - file: The file from which the log is called. Defaults to the current file.
    ///   - function: The function from which the log is called. Defaults to the current function.
    ///   - line: The line number from which the log is called. Defaults to the current line.
    ///   - plain: A Boolean indicating whether to log the message without additional formatting. Defaults to `false`.
    ///   - logType: The type of log message, defined by `LogTypeEnum`. Defaults to `.normal`.
    func printLog(
        _ message: Any = "",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        plain: Bool = false,
        logType: LogTypeEnum = .normal
    ) {
        // Extract the filename from the file path.
        let filename = (file as NSString).lastPathComponent
        
        // Construct the formatted log message with date, file, function, and line information.
        let message = "\(self.getCurrentDateAsString()) [\(filename) \(function) line \(line)]\n\(String(describing: message))"
        
        // Log the message using the appropriate log level based on `logType`.
        switch logType {
        case .error:
            logger.critical("\(message)")
        case .warning:
            logger.warning("\(message)")
        default:
            logger.info("\(message)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Retrieves the current date and time as a formatted string.
    ///
    /// - Returns: A `String` representing the current date and time in the format "yyyy-MM-dd HH:mm:ss.SSSZZZZZ".
    private func getCurrentDateAsString() -> String {
        let dateFormatter = DateFormatter()
        // Set the date format to include date, time, and timezone information.
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZZZ"
        // Set the time zone to Indian Standard Time (IST).
        dateFormatter.timeZone = TimeZone(identifier: "IST")
        
        let currentDate = Date()
        // Format the current date into a string.
        let formattedDateString = dateFormatter.string(from: currentDate)
        
        return formattedDateString
    }
}

/// An enumeration defining the types of log messages.
/// Each case can carry additional information as needed.
enum LogTypeEnum {
    /// Represents an error log message, optionally with an associated `Error` and detail string.
    case error(error: Error? = nil, detail: String? = nil)
    /// Represents a normal log message.
    case normal
    /// Represents a warning log message.
    case warning
}
