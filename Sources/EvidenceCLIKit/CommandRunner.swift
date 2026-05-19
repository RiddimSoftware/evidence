import Foundation

public struct CommandResult: Equatable {
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String

    public init(exitCode: Int32, stdout: String = "", stderr: String = "") {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

public protocol CommandRunning {
    @discardableResult
    func run(_ executable: String, _ arguments: [String]) throws -> CommandResult

    @discardableResult
    func run(
        _ executable: String,
        _ arguments: [String],
        workingDirectory: URL?,
        environment: [String: String]
    ) throws -> CommandResult
}

public extension CommandRunning {
    @discardableResult
    func run(
        _ executable: String,
        _ arguments: [String],
        workingDirectory: URL?,
        environment: [String: String]
    ) throws -> CommandResult {
        try run(executable, arguments)
    }
}

public struct ProcessCommandRunner: CommandRunning {
    public init() {}

    @discardableResult
    public func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        try run(executable, arguments, workingDirectory: nil, environment: [:])
    }

    @discardableResult
    public func run(
        _ executable: String,
        _ arguments: [String],
        workingDirectory: URL?,
        environment: [String: String]
    ) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        if !environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        var stdoutData = Data()
        var stderrData = Data()
        let stdoutLock = NSLock()
        let stderrLock = NSLock()

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            stdoutLock.lock()
            stdoutData.append(data)
            stdoutLock.unlock()
        }
        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            stderrLock.lock()
            stderrData.append(data)
            stderrLock.unlock()
        }
        defer {
            stdout.fileHandleForReading.readabilityHandler = nil
            stderr.fileHandleForReading.readabilityHandler = nil
        }

        try process.run()
        process.waitUntilExit()

        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        let remainingStdout = stdout.fileHandleForReading.readDataToEndOfFile()
        let remainingStderr = stderr.fileHandleForReading.readDataToEndOfFile()
        stdoutLock.lock()
        stdoutData.append(remainingStdout)
        let finalStdout = stdoutData
        stdoutLock.unlock()
        stderrLock.lock()
        stderrData.append(remainingStderr)
        let finalStderr = stderrData
        stderrLock.unlock()

        return CommandResult(
            exitCode: process.terminationStatus,
            stdout: String(data: finalStdout, encoding: .utf8) ?? "",
            stderr: String(data: finalStderr, encoding: .utf8) ?? ""
        )
    }
}
