import Foundation

/// Model for GitHub Release
struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let body: String
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case body
        case assets
    }
}

struct GitHubAsset: Codable {
    let browserDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case browserDownloadUrl = "browser_download_url"
    }
}

/// Manages update checking against GitHub Releases
@MainActor
class UpdateManager: ObservableObject {
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var downloadURL: URL?
    @Published var lastCheckError: String?
    @Published var isChecking: Bool = false
    
    // GitHub Release Configuration
    private let githubOwner = "vexar-app"
    private let githubRepo = "vexar-app"
    
    func checkForUpdates() async {
        guard let url = URL(string: "https://api.github.com/repos/\(githubOwner)/\(githubRepo)/releases/latest") else { return }
        
        isChecking = true
        lastCheckError = nil
        
        do {
            var request = URLRequest(url: url)
            request.setValue("VexarApp/1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                lastCheckError = "Server returned status \(httpResponse.statusCode)"
                isChecking = false
                return
            }
            
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            
            if isNewerVersion(remote: release.tagName, current: currentVersion) {
                self.latestVersion = release.tagName
                self.releaseNotes = release.body
                
                // Find .dmg or .zip asset
                if let asset = release.assets.first(where: { $0.browserDownloadUrl.hasSuffix(".dmg") || $0.browserDownloadUrl.hasSuffix(".zip") }) {
                    self.downloadURL = URL(string: asset.browserDownloadUrl)
                } else {
                    self.downloadURL = URL(string: release.htmlUrl) // Fallback to release page
                }
                
                self.isUpdateAvailable = true
                TelemetryManager.shared.sendEvent(eventName: "update_available", parameters: ["version": release.tagName, "current": currentVersion])
            }
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                lastCheckError = "İnternet bağlantısı yok"
            case .timedOut:
                lastCheckError = "Bağlantı zaman aşımına uğradı"
            default:
                lastCheckError = "Ağ hatası: \(error.localizedDescription)"
            }
            print("[Vexar] Update check failed: \(error)")
        } catch {
            lastCheckError = "Güncelleme kontrolü başarısız"
            print("[Vexar] Update check failed: \(error)")
        }
        
        isChecking = false
    }
    
    private func isNewerVersion(remote: String, current: String) -> Bool {
        // Cleaning function
        func clean(_ v: String) -> [Int] {
            return v.replacingOccurrences(of: "v", with: "")
                .components(separatedBy: CharacterSet(charactersIn: ".-"))
                .compactMap { Int($0) }
        }
        
        let remoteComponents = clean(remote)
        let currentComponents = clean(current)
        
        let maxLength = max(remoteComponents.count, currentComponents.count)
        
        for i in 0..<maxLength {
            let rVal = i < remoteComponents.count ? remoteComponents[i] : 0
            let cVal = i < currentComponents.count ? currentComponents[i] : 0
            
            if rVal > cVal {
                return true
            } else if rVal < cVal {
                return false
            }
        }
        
        return false
    }
}
