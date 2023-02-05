//
//  StreamLogHandler.swift
//  WebTags
//
//  Created by Nonstrict on 02/02/2023.
//

import Foundation
import Logging

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxx"
    return formatter
}()

/// `StreamLogHandler` is a simple implementation of `LogHandler` for directing
/// `Logger` output to either `stderr` or `stdout` via the factory methods.
public struct StreamLogHandler: LogHandler {
    #if compiler(>=5.6)
    internal typealias _SendableTextOutputStream = TextOutputStream & Sendable
    #else
    internal typealias _SendableTextOutputStream = TextOutputStream
    #endif

    /// Factory that makes a `StreamLogHandler` to directs its output to `stdout`
    public static func standardOutput(label: String) -> StreamLogHandler {
        return StreamLogHandler(label: label, stream: StdioOutputStream.stdout)
    }

    /// Factory that makes a `StreamLogHandler` to directs its output to `stderr`
    public static func standardError(label: String) -> StreamLogHandler {
        return StreamLogHandler(label: label, stream: StdioOutputStream.stderr)
    }

    private let stream: _SendableTextOutputStream
    private let label: String

    public var logLevel: Logger.Level = .info

    private var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }

    // internal for testing only
    internal init(label: String, stream: _SendableTextOutputStream) {
        self.label = label
        self.stream = stream
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        let prettyMetadata = metadata?.isEmpty ?? true
            ? self.prettyMetadata
            : self.prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))

        let paddedLevel = level.rawValue.padding(toLength: "critical".count, withPad: " ", startingAt: 0)

        var stream = self.stream
        stream.write("\(self.slowTimestamp()) \(paddedLevel) [\(source)] \(message)\(prettyMetadata.map { " \($0)" } ?? "")\n")
    }

    private func prettify(_ metadata: Logger.Metadata) -> String? {
        return !metadata.isEmpty
            ? metadata.lazy.sorted(by: { $0.key < $1.key }).map { "\($0)=\($1)" }.joined(separator: " ")
            : nil
    }

    private func slowTimestamp() -> String {
        dateFormatter.string(from: Date())
    }

    private func timestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        #if os(Windows)
        var timestamp: __time64_t = __time64_t()
        _ = _time64(&timestamp)

        var localTime: tm = tm()
        _ = _localtime64_s(&localTime, &timestamp)

        _ = strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", &localTime)
        #else
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        #endif
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
}

internal typealias CFilePointer = UnsafeMutablePointer<FILE>
let systemStderr = Darwin.stderr
let systemStdout = Darwin.stdout

/// A wrapper to facilitate `print`-ing to stderr and stdio that
/// ensures access to the underlying `FILE` is locked to prevent
/// cross-thread interleaving of output.
internal struct StdioOutputStream: TextOutputStream {
    internal let file: CFilePointer
    internal let flushMode: FlushMode

    internal func write(_ string: String) {
        self.contiguousUTF8(string).withContiguousStorageIfAvailable { utf8Bytes in
            #if os(Windows)
            _lock_file(self.file)
            #elseif canImport(WASILibc)
            // no file locking on WASI
            #else
            flockfile(self.file)
            #endif
            defer {
                #if os(Windows)
                _unlock_file(self.file)
                #elseif canImport(WASILibc)
                // no file locking on WASI
                #else
                funlockfile(self.file)
                #endif
            }
            _ = fwrite(utf8Bytes.baseAddress!, 1, utf8Bytes.count, self.file)
            if case .always = self.flushMode {
                self.flush()
            }
        }!
    }

    /// Flush the underlying stream.
    /// This has no effect when using the `.always` flush mode, which is the default
    internal func flush() {
        _ = fflush(self.file)
    }

    internal func contiguousUTF8(_ string: String) -> String.UTF8View {
        var contiguousString = string
        #if compiler(>=5.1)
        contiguousString.makeContiguousUTF8()
        #else
        contiguousString = string + ""
        #endif
        return contiguousString.utf8
    }

    internal static let stderr = StdioOutputStream(file: systemStderr, flushMode: .always)
    internal static let stdout = StdioOutputStream(file: systemStdout, flushMode: .always)

    /// Defines the flushing strategy for the underlying stream.
    internal enum FlushMode {
        case undefined
        case always
    }
}
