import SwiftUI
import Combine
import ServiceManagement
import Network

/// Central state management for the Vexar app
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Connection State
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isInternetAvailable: Bool = true
    @AppStorage("userInitiatedDisconnect") var userInitiatedDisconnect: Bool = false
    
    // DNS Settings
    @AppStorage("selectedDNSID") var selectedDNSID: String = "cloudflare" // Default to Cloudflare manual
    @AppStorage("isAutoDNS") var isAutoDNS: Bool = false
    
    let dnsManager = DNSManager()
    
    // Core Managers
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var quittingStatus: String = "Kapatılıyor..."
    
    // MARK: - Settings
    // Obsolete port setting, kept for legacy compatibility but not actively used for connection logic
    // Connection now uses dynamic port from ProcessManager
    @AppStorage("proxyPort") var legacyPort: Int = 8080
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    
    @AppStorage("autoConnect") var autoConnect: Bool = false
    // Removed legacy useCustomDNS
    
    @AppStorage("isAnalyticsEnabled") var isAnalyticsEnabled: Bool = true
    
    // MARK: - Managers
    let processManager: ProcessManager
    let discordManager: DiscordManager
    let networkStatsManager = NetworkStatsManager()
    @Published var updateManager: UpdateManager
    
    // MARK: - Live Stats
    @Published var currentLatency: Int = 0
    @Published var shouldMeasureLatency: Bool = false
    @Published var isDiscordRunning: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.processManager = ProcessManager()
        self.discordManager = DiscordManager()
        self.updateManager = UpdateManager()
        
        setupBindings()
        startNetworkMonitoring()
        startDiscordMonitoring()
        
        Task {
            await updateManager.checkForUpdates()
        }
        
        // Ensure safe cleanup on app exit
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.processManager.stopBlocking()
            }
        }
        
        checkLaunchAtLoginStatus()
    }

    // ... (existing code monitoring)

    // MARK: - Discord Monitoring
    private func startDiscordMonitoring() {
        // Light check every 3 seconds
        Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                let apps = NSWorkspace.shared.runningApplications
                let isRunning = apps.contains { app in
                    app.bundleIdentifier == "com.hnc.Discord" ||
                    app.localizedName == "Discord"
                }
                
                if self?.isDiscordRunning != isRunning {
                    withAnimation {
                        self?.isDiscordRunning = isRunning
                    }
                }
            }
            .store(in: &cancellables)
    }

    func startLatencyMonitoring() {
        shouldMeasureLatency = true
        Task {
            while shouldMeasureLatency {
                // Only measure if Connected + Internet + Discord Running
                if isConnected && isInternetAvailable && isDiscordRunning {
                    if let ms = await networkStatsManager.measureDiscordLatency() {
                        await MainActor.run {
                            withAnimation { self.currentLatency = ms }
                        }
                    }
                } else {
                    await MainActor.run { 
                        if self.currentLatency != 0 {
                            withAnimation { self.currentLatency = 0 }
                        }
                    }
                }
                
                // Wait 5 seconds before next ping
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            }
        }
    }
    
    /// Syncs the 'Launch at Login' toggle with the actual system status
    func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            // System settings override app settings
            if status == .enabled && !launchAtLogin {
                launchAtLogin = true
            } else if status != .enabled && launchAtLogin {
                launchAtLogin = false
            }
        }
    }

    
    private func setupBindings() {
        // Forward DNSManager updates to UI
        dnsManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
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
        userInitiatedDisconnect = false
        
        Task {
            do {
                // Determine DNS
                var dnsAddress: String? = nil
                
                if isAutoDNS {
                    // Force refresh ping if needed
                    await dnsManager.measureAllLatencies()
                    if let best = dnsManager.bestServer {
                        dnsAddress = best.address
                        addLog("⚡️ Otomatik DNS seçildi: \(best.name) (\(dnsManager.latencies[best.id] ?? 0)ms)")
                    }
                } else {
                    if let server = dnsManager.servers.first(where: { $0.id == selectedDNSID }) {
                        dnsAddress = server.address
                    }
                }
                
                // Start with custom DNS
                try await processManager.start(dnsAddress: dnsAddress)
                
            } catch {
                addLog("❌ Connection failed: \(error.localizedDescription)")
            }
            isConnecting = false
        }
    }
    
    func disconnect() {
        processManager.stop()
        userInitiatedDisconnect = true
        addLog("🔌 Disconnected")
    }
    
    func clearLogs() {
        processManager.clearLogs()
    }
    
    private func addLog(_ message: String) {
        processManager.addLog(message)
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
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isInternetAvailable = path.status == .satisfied
                
                if path.status != .satisfied {
                    self?.addLog("⚠️ İnternet bağlantısı koptu")
                } else {
                    // Auto Connect Logic
                    if let self = self, self.autoConnect && !self.isConnected && !self.isConnecting && !self.userInitiatedDisconnect {
                        self.addLog("🔄 İnternet algılandı, otomatik bağlanılıyor...")
                        self.connect()
                    }
                }
            }
        }
        monitor?.start(queue: monitorQueue)
    }
    
    func stopLatencyMonitoring() {
        shouldMeasureLatency = false
    }
    
    deinit {
        monitor?.cancel()
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



