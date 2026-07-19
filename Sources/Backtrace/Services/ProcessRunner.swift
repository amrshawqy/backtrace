import Foundation

struct ProcessResult: Sendable {
    let status: Int32
    let output: Data

    var text: String {
        String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ProcessRunner {
    static func run(
        executable: URL,
        arguments: [String],
        currentDirectory: URL? = nil,
        extraEnvironment: [String: String] = [:]
    ) -> ProcessResult? {
        ProcessOperation(
            executable: executable,
            arguments: arguments,
            currentDirectory: currentDirectory,
            extraEnvironment: extraEnvironment
        ).run()
    }

    static func runCancellable(
        executable: URL,
        arguments: [String],
        currentDirectory: URL? = nil,
        extraEnvironment: [String: String] = [:]
    ) async -> ProcessResult? {
        let operation = ProcessOperation(
            executable: executable,
            arguments: arguments,
            currentDirectory: currentDirectory,
            extraEnvironment: extraEnvironment
        )
        let worker = Task.detached(priority: .utility) {
            operation.run()
        }

        return await withTaskCancellationHandler {
            await worker.value
        } onCancel: {
            operation.cancel()
            worker.cancel()
        }
    }
}

private final class ProcessOperation: @unchecked Sendable {
    private let process = Process()
    private let pipe = Pipe()
    private let lock = NSLock()
    private var wasCancelled = false

    init(
        executable: URL,
        arguments: [String],
        currentDirectory: URL?,
        extraEnvironment: [String: String]
    ) {
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory
        process.standardOutput = pipe
        process.standardError = pipe
        process.environment = ProcessInfo.processInfo.environment.merging(extraEnvironment) { _, new in new }
    }

    func run() -> ProcessResult? {
        lock.lock()
        let cancelledBeforeLaunch = wasCancelled
        lock.unlock()
        guard !cancelledBeforeLaunch else { return nil }

        do {
            try process.run()

            lock.lock()
            let cancelAfterLaunch = wasCancelled
            lock.unlock()
            if cancelAfterLaunch, process.isRunning {
                process.terminate()
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return ProcessResult(status: process.terminationStatus, output: data)
        } catch {
            return nil
        }
    }

    func cancel() {
        lock.lock()
        wasCancelled = true
        let shouldTerminate = process.isRunning
        lock.unlock()

        if shouldTerminate {
            process.terminate()
        }
    }
}
