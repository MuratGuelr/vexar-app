import Foundation
import Combine
import Network

/// Manages the spoof-dpi process execution
@MainActor
final class ProcessManager: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var logs: [String] = []
    // Add current port property to be read by others if needed, though UI won't show it explicitly
    @Published private(set) var currentPort: Int = 8080
    
    // Thread-safe process management
    private let processLock = NSLock()
    nonisolated(unsafe) private var _process: Process?
    
    private var process: Process? {
        get {
            processLock.lock()
            defer { processLock.unlock() }
            return _process
        }
        set {
            processLock.lock()
            defer { processLock.unlock() }
            _process = newValue
        }
    }
    
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    // Auto-recovery
    private var crashCount = 0
    private let maxCrashCount = 3
    private var lastCrashTime: Date?
    private var isUserInitiatedStop = false
    private var _dnsAddress: String? = nil
    
    enum ProcessError: LocalizedError {
        case binaryNotFound
        case alreadyRunning
        case startFailed(String)
        case noPortsAvailable
        
        var errorDescription: String? {
            switch self {
            case .binaryNotFound:
                return "spoofdpi binary not found. Please install via Homebrew: brew install spoofdpi"
            case .alreadyRunning:
                return "Process is already running"
            case .startFailed(let reason):
                return "Failed to start process: \(reason)"
            case .noPortsAvailable:
                return "No available ports found to start the service"
            }
        }
    }
    
    /// Start the spoof-dpi process
    nonisolated func start(dnsAddress: String?) async throws {
        // Reset manual stop flag
        await MainActor.run { 
            self.isUserInitiatedStop = false 
            self._dnsAddress = dnsAddress
        }
        
        // Kill any existing instances to prevent conflicts
        killExistingProcesses()
        
        // Wait a brief moment for cleanup
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        let binaryPath = findBinary()
        guard let binaryPath = binaryPath else {
            throw ProcessError.binaryNotFound
        }
        
        // Find an available port
        let port = try findAvailablePort()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        
        // SpoofDPI v1.2.1 arguments:
        // --listen-addr string: IP address and port to listen on (default: 127.0.0.1:8080)
        // --dns-addr string: DNS server address (default: 8.8.8.8) - Using Cloudflare 1.1.1.1 for speed
        // --log-level string: Set log level (default: "info")
        // --system-proxy bool: Automatically set system-wide proxy configuration
        process.arguments = [
            "--listen-addr", "127.0.0.1:\(port)",
            "--log-level", "info",
            "--system-proxy"
        ]
        
        if let dns = dnsAddress, !dns.isEmpty {
            process.arguments?.append(contentsOf: ["--dns-addr", dns])
        }
        
        // Setup pipes for output capture
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        await MainActor.run {
            self.outputPipe = outputPipe
            self.errorPipe = errorPipe
            self.process = process
            self.currentPort = port
        }
        
        // Read output asynchronously
        await setupOutputReading(from: outputPipe.fileHandleForReading, prefix: "")
        await setupOutputReading(from: errorPipe.fileHandleForReading, prefix: "")
        
        // Handle termination
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                self?.handleTermination(proc)
            }
        }
        
        do {
            try process.run()
            await MainActor.run {
                self.isRunning = true
                self.appendLog("✅ Started spoofdpi on port \(port)")
                // Reset crash count on successful start after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                    if self.isRunning {
                        self.crashCount = 0
                    }
                }
            }
        } catch {
            throw ProcessError.startFailed(error.localizedDescription)
        }
    }
    
    /// Kill any existing spoofdpi processes to ensure a clean state
    /// Safely target only the current user's processes using pkill -u
    nonisolated private func killExistingProcesses() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        // -x: exact name match
        // -u: targets only processes owned by current effective user ID
        process.arguments = ["-x", "-u", "\(geteuid())", "spoofdpi"]
        process.standardOutput = Pipe() // Suppress output
        process.standardError = Pipe() // Suppress errors (like "no process found")
        try? process.run()
        process.waitUntilExit()
    }
    
    /// Stop the running process
    func stop() {
        isUserInitiatedStop = true
        guard let process = process, process.isRunning else {
            isRunning = false
            closePipes()
            return
        }
        
        process.terminate()
        closePipes()
        
        self.process = nil
        isRunning = false
    }
    
    /// Stops the process handling the exit synchronously to ensure cleanup
    /// Used when application is terminating
    func stopBlocking() {
        // Safe to read just the process reference, but need to be careful with other state
        // Since we are shutting down, strict isolation is less critical than ensuring the process dies
        guard let process = process, process.isRunning else { return }
        
        process.terminate()
        
        // Wait up to 2 seconds for clean exit (proxy cleanup)
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        DispatchQueue.global().async {
            process.waitUntilExit()
            dispatchGroup.leave()
        }
        
        _ = dispatchGroup.wait(timeout: .now() + 2.0)
        
        closePipes()
        self.process = nil
        self.isRunning = false
    }
    
    private func closePipes() {
        try? outputPipe?.fileHandleForReading.close()
        outputPipe = nil
        try? errorPipe?.fileHandleForReading.close()
        errorPipe = nil
    }

    /// Clear all logs
    func clearLogs() {
        // Trigger explicit UI update
        objectWillChange.send()
        // Replace with new empty array to force SwiftUI diffing
        logs = []
    }
    
    // MARK: - Private Helpers
    
    private func handleTermination(_ process: Process) {
        isRunning = false
        appendLog("🔴 Process terminated (Exit code: \(process.terminationStatus))")
        
        // Auto-recovery logic
        if !isUserInitiatedStop && process.terminationStatus != 0 {
            let now = Date()
            if let last = lastCrashTime, now.timeIntervalSince(last) > 60 {
                // Reset count if last crash was over a minute ago
                crashCount = 0
            }
            
            if crashCount < maxCrashCount {
                crashCount += 1
                lastCrashTime = now
                appendLog("⚠️ Unexpected termination. Attempting restart (\(crashCount)/\(maxCrashCount))...")
                
                Task {
                    // Wait a bit before restart
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    try? await start(dnsAddress: self._dnsAddress)
                }
            } else {
                appendLog("❌ Maximum restart attempts reached. Please check logs.")
            }
        }
    }
    
    nonisolated private func findBinary() -> String? {
        let allPaths = [
            "/opt/homebrew/bin/spoofdpi",   // Apple Silicon
            "/usr/local/bin/spoofdpi",       // Intel
            Bundle.main.path(forResource: "spoofdpi", ofType: nil)
        ].compactMap { $0 }
        
        for path in allPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    nonisolated private func findAvailablePort() throws -> Int {
        // Range of ports to check
        let portRange = 8080...8090
        
        for port in portRange {
            if isPortAvailable(port: UInt16(port)) {
                print("[Vexar] Found available port: \(port)")
                return port
            }
        }
        
        throw ProcessError.noPortsAvailable
    }
    
    nonisolated private func isPortAvailable(port: UInt16) -> Bool {
        // Create a socket to check if port is in use
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = in_addr_t(0) // INADDR_ANY
        
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        if socketFileDescriptor == -1 {
            return false // Socket creation failed
        }
        
        var bindResult: Int32 = -1
        let addrSize = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socketFileDescriptor, $0, addrSize)
            }
        }
        
        _ = close(socketFileDescriptor)
        
        // If bind was successful (0), the port is available
        return bindResult == 0
    }
    
    // MARK: - Logging System
    
    // Nested helper class to manage log buffering in a thread-safe way
    private class LogBuffer: @unchecked Sendable {
        private var buffer: [String] = []
        private var isFlushPending = false
        private let lock = NSLock()
        
        func append(_ lines: [String]) {
            lock.lock()
            defer { lock.unlock() }
            buffer.append(contentsOf: lines)
        }
        
        func takeAll() -> [String] {
            lock.lock()
            defer { lock.unlock() }
            let items = buffer
            buffer.removeAll()
            return items
        }
        
        func setflushPending(_ value: Bool) {
            lock.lock()
            defer { lock.unlock() }
            isFlushPending = value
        }
        
        func checkAndSetPending() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if isFlushPending { return false }
            isFlushPending = true
            return true
        }
    }
    
    // Thread-safe log buffer instance
    private let logBuffer = LogBuffer()
    
    private func setupOutputReading(from fileHandle: FileHandle, prefix: String) {
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let output = String(data: data, encoding: .utf8) else {
                return
            }
            
            let lines = output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { "\(prefix)\($0)" }
            
            self?.queueLogs(lines)
        }
    }
    
    nonisolated private func queueLogs(_ lines: [String]) {
        // Appending is safe via lock
        logBuffer.append(lines)
        
        // Schedule flush if not already pending
        if logBuffer.checkAndSetPending() {
            // Throttle updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.flushLogs()
            }
        }
    }
    
    nonisolated private func flushLogs() {
        let logsToAppend = logBuffer.takeAll()
        logBuffer.setflushPending(false)
        
        if logsToAppend.isEmpty { return }
        
        Task { @MainActor in
            self.batchAppendLogs(logsToAppend)
        }
    }
    
    private func batchAppendLogs(_ messages: [String]) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        for message in messages {
            logs.append("[\(timestamp)] \(message)")
        }
        
        if logs.count > 300 {
            logs.removeFirst(logs.count - 200)
        }
    }
    
    /// Direct append for internal/external messages
    nonisolated func addLog(_ message: String) {
        queueLogs([message])
    }
    
    // Internal helper for existing calls (redirects to addLog)
    nonisolated private func appendLog(_ message: String) {
        addLog(message)
    }
    
    deinit {
        // Access backing storage directly to avoid MainActor check
        _process?.terminate()
        resetSystemProxies()
    }

    /// Attempts to reset system proxy settings for all available network services
    /// This is a safeguard against SpoofDPI crashing and leaving proxies enabled
    nonisolated private func resetSystemProxies() {
        // 1. Get list of all network services
        let listProcess = Process()
        listProcess.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        listProcess.arguments = ["-listallnetworkservices"]
        
        let pipe = Pipe()
        listProcess.standardOutput = pipe
        
        do {
            try listProcess.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            if let output = String(data: data, encoding: .utf8) {
                let services = output.components(separatedBy: .newlines)
                    .filter { line in
                        !line.isEmpty && 
                        !line.contains("An asterisk") && // Skip instructional header
                        !line.contains("(*)") // Skip explicitly disabled services if you want, or include them to be safe. Usually we only care about active ones, but resetting disabled ones doesn't hurt.
                    }
                
                // 2. Reset each service
                for service in services {
                    // Turn off web proxy
                    let webProxy = Process()
                    webProxy.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
                    webProxy.arguments = ["-setwebproxystate", service, "off"]
                    try? webProxy.run()
                    
                    // Turn off secure web proxy
                    let secureWebProxy = Process()
                    secureWebProxy.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
                    secureWebProxy.arguments = ["-setsecurewebproxystate", service, "off"]
                    try? secureWebProxy.run()
                }
            }
        } catch {
            print("[Vexar] Failed to reset system proxies: \(error)")
        }
    }
}
