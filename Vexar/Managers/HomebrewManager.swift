import Foundation
import AppKit

/// Manages Homebrew and SpoofDPI installation with Intel/Apple Silicon detection
@MainActor
final class HomebrewManager: ObservableObject {
    static let shared = HomebrewManager()
    
    @Published var isHomebrewInstalled: Bool = false
    @Published var isSpoofDPIInstalled: Bool = false
    @Published var isInstalling: Bool = false
    @Published var installProgress: String = ""
    @Published var installError: String?
    @Published var cpuArchitecture: CPUArchitecture = .unknown
    @Published var installCommand: String = ""
    
    enum CPUArchitecture: String {
        case applesilicon = "arm64"
        case intel = "x86_64"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .applesilicon: return "Apple Silicon (M1/M2/M3/M4)"
            case .intel: return "Intel"
            case .unknown: return "Unknown"
            }
        }
    }
    
    init() {
        detectArchitecture()
        checkInstallations()
    }
    
    /// Detect CPU architecture
    private func detectArchitecture() {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
        
        if machine == "arm64" {
            cpuArchitecture = .applesilicon
        } else if machine == "x86_64" {
            cpuArchitecture = .intel
        } else {
            cpuArchitecture = .unknown
        }
        
        print("[Vexar] Detected CPU: \(cpuArchitecture.displayName)")
    }
    
    /// Check installations
    func checkInstallations() {
        let homebrewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        isHomebrewInstalled = homebrewPaths.contains { FileManager.default.fileExists(atPath: $0) }
        
        let spoofDPIPaths = ["/opt/homebrew/bin/spoofdpi", "/usr/local/bin/spoofdpi"]
        isSpoofDPIInstalled = spoofDPIPaths.contains { FileManager.default.fileExists(atPath: $0) }
        
        print("[Vexar] Homebrew: \(isHomebrewInstalled), SpoofDPI: \(isSpoofDPIInstalled)")
    }
    
    /// Get Homebrew path
    func getHomebrewPath() -> String? {
        // 1. Check standard paths
        let paths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        if let found = paths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            return found
        }
        
        // 2. Dynamic check (fallback)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty,
               FileManager.default.fileExists(atPath: path) {
                return path
            }
        } catch {
            print("[Vexar] 'which brew' check failed: \(error)")
        }
        
        return nil
    }
    
    /// Get SpoofDPI path
    func getSpoofDPIPath() -> String? {
        let paths = ["/opt/homebrew/bin/spoofdpi", "/usr/local/bin/spoofdpi"]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }
    
    /// Get secure temporary script path
    private func getTempScriptPath(_ name: String) -> String {
        return FileManager.default.temporaryDirectory.appendingPathComponent(name).path
    }
    
    /// Clean up temporary installation scripts
    private func cleanupTempScripts() {
        let tempScripts = [
            "vexar_install.sh",
            "vexar_discord_install.sh",
            "vexar_homebrew.sh",
            "vexar_discord_uninstall.sh",
            "vexar_brew_uninstall.sh",
            "vexar_self_destruct.sh"
        ]
        for script in tempScripts {
            try? FileManager.default.removeItem(atPath: getTempScriptPath(script))
        }
    }
    
    /// Install SpoofDPI - copies command and opens Terminal
    func installSpoofDPI() async -> Bool {
        cleanupTempScripts() // Clean up old scripts first
        
        guard let brewPath = getHomebrewPath() else {
            installError = String(localized: "homebrew_not_found")
            return false
        }
        
        isInstalling = true
        installError = nil
        
        let command = "\(brewPath) install spoofdpi"
        installCommand = command
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        
        // Open Terminal using shell script approach
        let scriptPath = getTempScriptPath("vexar_install.sh")
        let scriptContent = """
        #!/bin/bash
        echo "🔧 Ön Temizlik Yapılıyor..."
        # Prevent service conflicts
        \(brewPath) services stop spoofdpi 2>/dev/null
        killall spoofdpi 2>/dev/null
        
        echo "⬇️ SpoofDPI Kuruluyor..."
        \(command)
        
        echo ""
        echo "✅ Kurulum tamamlandı! Bu pencereyi kapatabilirsiniz."
        read -p "Devam etmek için Enter'a basın..."
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            // Open Terminal with the script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Terminal", scriptPath]
            try process.run()
            
            installProgress = String(localized: "spoofdpi_installing_progress")
            
            // Poll for installation (max 2 minutes)
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Check every 2s
                checkInstallations()
                if isSpoofDPIInstalled {
                    installProgress = String(localized: "install_complete")
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    isInstalling = false
                    TelemetryManager.shared.sendEvent(eventName: "install_spoofdpi", parameters: ["status": "success", "method": "automated"])
                    
                    // Notify other managers (e.g. Main Window) to refresh
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshInstallations"), object: nil)
                    }
                    
                    return true
                }
            }
            
            // Timeout but maybe they are just slow?
            isInstalling = false
            return false
        } catch {
            print("[Vexar] Error: \(error)")
            installError = String(localized: "manual_install_instruction")
            isInstalling = false
            TelemetryManager.shared.sendEvent(eventName: "install_spoofdpi", parameters: ["status": "failed", "error": error.localizedDescription])
            return false
        }
    }
    
    
    /// Install Discord - copies command and opens Terminal
    func installDiscord() async -> Bool {
        guard let brewPath = getHomebrewPath() else {
            installError = String(localized: "homebrew_not_found")
            return false
        }
        
        isInstalling = true
        installError = nil
        
        // Use --cask for GUI apps
        let command = "\(brewPath) install --cask discord"
        installCommand = command
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        
        // Open Terminal using shell script approach
        let scriptPath = getTempScriptPath("vexar_discord_install.sh")
        let scriptContent = """
        #!/bin/bash
        echo "🎮 Discord Kuruluyor..."
        echo "Komut: \(command)"
        \(command)
        echo ""
        echo "✅ Discord kurulumu tamamlandı! Bu pencereyi kapatabilirsiniz."
        read -p "Devam etmek için Enter'a basın..."
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            // Open Terminal with the script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Terminal", scriptPath]
            try process.run()
            
            installProgress = "Discord kuruluyor... Lütfen Terminal'i takip edin."
            
            // Poll for installation (max 5 minutes for Discord as it's large)
            for _ in 0..<150 {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                if FileManager.default.fileExists(atPath: "/Applications/Discord.app") {
                    installProgress = "Discord başarıyla kuruldu!"
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    isInstalling = false
                    TelemetryManager.shared.sendEvent(eventName: "install_discord", parameters: ["status": "success"])
                    
                    // Notify other managers (e.g. Main Window) to refresh
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshInstallations"), object: nil)
                    }
                    
                    return true
                }
            }
            
            isInstalling = false
            return false
        } catch {
            print("[Vexar] Error: \(error)")
            installError = "Komut panoya kopyalandı.\nTerminal'i açıp yapıştırın: ⌘V"
            isInstalling = false
            TelemetryManager.shared.sendEvent(eventName: "install_discord", parameters: ["status": "failed", "error": error.localizedDescription])
            return false
        }
    }
    
    /// Install Homebrew
    func openTerminalForHomebrew() async {
        isInstalling = true
        let command = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        installCommand = command
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        
        // Create script file
        let scriptPath = getTempScriptPath("vexar_homebrew.sh")
        let scriptContent = """
        #!/bin/bash
        echo "🍺 Homebrew Kuruluyor..."
        echo "Lütfen şifrenizi girin (yazarken görünmez) ve Enter'a basın."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo ""
        echo "✅ İşlem tamamlandı! Pencereyi kapatabilirsiniz."
        read -p "Bitirmek için Enter..."
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Terminal", scriptPath]
            try process.run()
            
            installProgress = "Homebrew kuruluyor... Bu işlem biraz sürebilir."
            
            // Poll for Homebrew (max 10 minutes)
            for _ in 0..<300 {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                checkInstallations()
                if isHomebrewInstalled {
                    installProgress = "Homebrew başarıyla kuruldu!"
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    isInstalling = false
                    return
                }
            }
            
            isInstalling = false
        } catch {
            print("[Vexar] Error: \(error)")
            installError = "Komut panoya kopyalandı.\nTerminal'i açıp yapıştırın: ⌘V"
            isInstalling = false
        }
    }

    // MARK: - Uninstallation Logic
    
    /// Uninstall SpoofDPI
    func uninstallSpoofDPI() async -> Bool {
        // 1. Stop the process
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killProcess.arguments = ["spoofdpi"]
        try? killProcess.run()
        killProcess.waitUntilExit()
        
        // 2. Uninstall via Homebrew
        guard let brewPath = getHomebrewPath() else { return false }
        
        // Try running directly first
        let command = "\(brewPath) uninstall spoofdpi"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            checkInstallations()
            TelemetryManager.shared.sendEvent(eventName: "uninstall_spoofdpi", parameters: ["status": "success"])
            return true
        } catch {
            print("[Vexar] Failed to uninstall SpoofDPI: \(error)")
            return false
        }
    }
    
    /// Uninstall Discord
    func uninstallDiscord() async -> Bool {
        guard let brewPath = getHomebrewPath() else { return false }
        
        let scriptPath = getTempScriptPath("vexar_discord_uninstall.sh")
        let scriptContent = """
        #!/bin/bash
        echo "🗑️ Discord Kaldırılıyor..."
        \(brewPath) uninstall --cask discord
        echo "✅ Discord kaldırıldı."
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Terminal", scriptPath]
            try process.run()
            
            // Assume success for UI flow as it's external
            return true
        } catch {
            return false
        }
    }
    
    /// Uninstall Homebrew
    func uninstallHomebrew() {
        let scriptPath = getTempScriptPath("vexar_brew_uninstall.sh")
        let scriptContent = """
        #!/bin/bash
        echo "🍺 Homebrew Kaldırılıyor..."
        echo "⚠️ Bu işlem tüm Homebrew paketlerini silecektir!"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Terminal", scriptPath]
            try process.run()
        } catch {
            print("[Vexar] Failed to launch brew uninstall: \(error)")
        }
    }
    
    /// Self Destruct: Deletes app support files and the app itself
    func selfDestruct() {
        // 1. Delete UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // 2. Prepare Self-Destruct Script
        let bundlePath = Bundle.main.bundlePath
        let scriptPath = getTempScriptPath("vexar_self_destruct.sh")
        
        let supportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Vexar").path ?? ""
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.vexar").path ?? ""
        
        let scriptContent = """
        #!/bin/bash
        echo "💥 Vexar kendini imha ediyor..."
        sleep 2
        
        echo "📂 Dosyalar temizleniyor..."
        rm -rf "\(supportPath)"
        rm -rf "\(cachesPath)"
        
        echo "🗑️ Uygulama siliniyor: \(bundlePath)"
        rm -rf "\(bundlePath)"
        
        echo "✅ Vexar bilgisayarınızdan tamamen kaldırıldı."
        sleep 1
        exit 0
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            // 3. Launch Script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Terminal", scriptPath]
            try process.run()
            
            // 4. Quit App Immediately
            NSApplication.shared.terminate(nil)
        } catch {
            print("[Vexar] Self destruct failed: \(error)")
        }
    }
}
