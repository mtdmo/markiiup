import OSLog

enum AppLogger {
    static let document = Logger(subsystem: "com.mtdmo.markiiupMac", category: "document")
    static let editor = Logger(subsystem: "com.mtdmo.markiiupMac", category: "editor")
    static let workspace = Logger(subsystem: "com.mtdmo.markiiupMac", category: "workspace")
}
