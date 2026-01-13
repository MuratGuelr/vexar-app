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
    
    nonisolated(unsafe) private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    // Auto-recovery
    private var crashCount = 0
    private let maxCrashCount = 3
    private var lastCrashTime: Date?
    private var isUserInitiatedStop = false
    
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
    nonisolated func start() async throws {
        // Reset manual stop flag
        await MainActor.run { self.isUserInitiatedStop = false }
        
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
        // --log-level string: Set log level (default: "info")
        // --system-proxy bool: Automatically set system-wide proxy configuration
        process.arguments = [
            "--listen-addr", "127.0.0.1:\(port)",
            "--log-level", "info",
            "--system-proxy"
        ]
        
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
    nonisolated private func killExistingProcesses() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["spoofdpi"]
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
            return
        }
        
        process.terminate()
        
        self.process = nil
        self.outputPipe = nil
        self.errorPipe = nil
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
        
        self.process = nil
        self.isRunning = false
    }
    
    /// Clear all logs
    func clearLogs() {
        logs.removeAll()
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
                    try? await start()
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
    
    private func setupOutputReading(from fileHandle: FileHandle, prefix: String) {
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let output = String(data: data, encoding: .utf8) else {
                return
            }
            
            let lines = output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
            
            Task { @MainActor in
                for line in lines {
                    self?.appendLog("\(prefix)\(line)")
                }
            }
        }
    }
    
    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        logs.append("[\(timestamp)] \(message)")
        
        if logs.count > 300 {
            logs.removeFirst(logs.count - 200)
        }
    }
    
    deinit {
        process?.terminate()
    }
}
