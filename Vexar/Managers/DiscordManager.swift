import Foundation
import AppKit

/// Manages Discord app launching with proxy configuration
final class DiscordManager {
    
    private var discordAppPath: String {
        if let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.hnc.Discord")?.path {
            return path
        }
        return "/Applications/Discord.app"
    }
    
    private var discordBinaryPath: String {
        return discordAppPath + "/Contents/MacOS/Discord"
    }
    
    enum DiscordError: LocalizedError {
        case notInstalled
        case launchFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notInstalled:
                return "Discord is not installed"
            case .launchFailed(let reason):
                return "Failed to launch Discord: \(reason)"
            }
        }
    }
    
    /// Check if Discord is installed
    var isDiscordInstalled: Bool {
        FileManager.default.fileExists(atPath: discordAppPath)
    }
    
    /// Kill any running Discord process
    func killDiscord(completion: @escaping () -> Void) {
        Task {
            let workspace = NSWorkspace.shared
            
            // 1. Initial Terminate Signal
            let runningApps = workspace.runningApplications.filter {
                $0.bundleIdentifier == "com.hnc.Discord" ||
                $0.bundleIdentifier?.contains("discord") == true ||
                $0.localizedName == "Discord"
            }
            
            for app in runningApps {
                app.terminate()
            }
            
            // 2. Poll for exit (Max 5 seconds)
            var retries = 0
            while retries < 20 { // 20 * 0.25s = 5s
                let currentRunning = workspace.runningApplications.filter {
                    $0.bundleIdentifier == "com.hnc.Discord" ||
                    $0.bundleIdentifier?.contains("discord") == true ||
                    $0.localizedName == "Discord"
                }
                
                if currentRunning.isEmpty {
                    break // All gone
                }
                
                // Aggressive kill after 2 seconds (8 retries)
                if retries == 8 {
                    for app in currentRunning {
                        app.forceTerminate()
                    }
                    // pkill backup
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
                    process.arguments = ["-9", "Discord"]
                    try? process.run()
                    process.waitUntilExit()
                }
                
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s
                retries += 1
            }
            
            // 3. Complete on Main Thread
            await MainActor.run {
                completion()
            }
        }
    }
    
    /// Launch Discord with proxy server flag
    func launchDiscord(withProxyPort port: Int, completion: ((Bool) -> Void)? = nil) {
        killDiscord { [self] in
            self.launchDiscordWithProxy(port: port, completion: completion)
        }
    }
    
    private func launchDiscordWithProxy(port: Int, completion: ((Bool) -> Void)?) {
        guard FileManager.default.fileExists(atPath: discordBinaryPath) else {
            print("[Vexar] Discord binary not found at \(discordBinaryPath)")
            completion?(false)
            return
        }
        
        // Discord uses Chromium, so it supports --proxy-server flag
        // SpoofDPI creates an HTTP proxy, so we use http://
        let proxyArg = "--proxy-server=http://127.0.0.1:\(port)"
        
        print("[Vexar] Launching Discord with: \(proxyArg)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: discordBinaryPath)
        process.arguments = [proxyArg]
        
        // Set environment to help with proxy
        var env = ProcessInfo.processInfo.environment
        env["HTTP_PROXY"] = "http://127.0.0.1:\(port)"
        env["HTTPS_PROXY"] = "http://127.0.0.1:\(port)"
        env["http_proxy"] = "http://127.0.0.1:\(port)"
        env["https_proxy"] = "http://127.0.0.1:\(port)"
        process.environment = env
        
        do {
            try process.run()
            print("[Vexar] Discord launched successfully with proxy on port \(port)")
            TelemetryManager.shared.sendEvent(eventName: "discord_launched", parameters: ["port": port, "status": "success"])
            completion?(true)
        } catch {
            print("[Vexar] Failed to launch Discord: \(error)")
            TelemetryManager.shared.sendEvent(eventName: "discord_launched", parameters: ["status": "failed", "error": error.localizedDescription])
            completion?(false)
        }
    }
    
    /// Launch Discord normally (without proxy)
    func launchDiscordNormally() {
        NSWorkspace.shared.open(URL(fileURLWithPath: discordAppPath))
    }
}
