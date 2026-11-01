import Foundation

/// A command run to its end, its output kept in a log file (a pipe would fill and stall a long build).
enum Shell {
    struct Run {
        let status: Int32
        let log: String
    }

    static func run(_ arguments: [String], in folder: URL, environment: [String: String] = [:]) throws -> Run {
        let log = FileManager.default.temporaryDirectory.appendingPathComponent("granite-run-\(UUID().uuidString.prefix(8)).log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: log) }
        let handle = try FileHandle(forWritingTo: log)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = folder
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        process.standardOutput = handle
        process.standardError = handle
        process.standardInput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        try handle.close()
        return Run(status: process.terminationStatus, log: (try? String(contentsOf: log, encoding: .utf8)) ?? "")
    }

    /// The lines of `log` a failed build is read by: errors, failed tests, the result.
    static func digest(_ log: String) -> String {
        log.components(separatedBy: "\n").filter { line in
            line.contains("error:") || line.contains("✘") || line.contains("** ") || line.contains("Test run with") || line.contains("failed")
        }.prefix(40).joined(separator: "\n")
    }
}
