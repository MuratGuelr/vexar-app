import SwiftUI
import Combine
import ServiceManagement

/// Central state management for the Vexar app
@MainActor
final class AppState: ObservableObject {
    // MARK: - Connection State
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    
    // MARK: - Settings
    // Obsolete port setting, kept for legacy compatibility but not actively used for connection logic
    // Connection now uses dynamic port from ProcessManager
    @AppStorage("proxyPort") var legacyPort: Int = 8080
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    
    // MARK: - Logs
    @Published var logs: [String] = []
    private let maxLogLines = 200
    
    // MARK: - Managers
    let processManager: ProcessManager
    let discordManager: DiscordManager
    @Published var updateManager: UpdateManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.processManager = ProcessManager()
        self.discordManager = DiscordManager()
        self.updateManager = UpdateManager()
        
        setupBindings()
        
        Task {
            await updateManager.checkForUpdates()
        }
        
        // Ensure safe cleanup on app exit
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.disconnect()
        }
    }

    
    private func setupBindings() {
        // Forward process logs to app state
        processManager.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLogs in
                guard let self = self else { return }
                self.logs = Array(newLogs.suffix(self.maxLogLines))
            }
            .store(in: &cancellables)
        
        // Track running state
        processManager.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning in
                self?.isConnected = isRunning
                // If stopped unexpectedly, isConnecting should also be false
                if !isRunning {
                    self?.isConnecting = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func connect() {
        guard !isConnected && !isConnecting else { return }
        isConnecting = true
        
        Task {
            do {
                try await processManager.start()
                // Log will be handled by ProcessManager
            } catch {
                addLog("❌ Connection failed: \(error.localizedDescription)")
            }
            isConnecting = false
        }
    }
    
    func disconnect() {
        processManager.stop()
        addLog("🔌 Disconnected")
    }
    
    func clearLogs() {
        logs.removeAll()
        processManager.clearLogs()
    }
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        logs.append("[\(timestamp)] \(message)")
        if logs.count > maxLogLines {
            logs.removeFirst(logs.count - maxLogLines)
        }
    }
    
    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            addLog("⚠️ Launch at login update failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
