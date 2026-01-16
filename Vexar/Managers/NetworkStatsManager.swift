import Foundation
import Combine

/// Manages network statistics and latency measurements
actor NetworkStatsManager {
    
    enum StatError: Error {
        case invalidURL
        case requestFailed
    }
    
    /// Measures latency to Discord's API endpoint
    /// Returns: Latency in milliseconds, or nil if failed
    func measureDiscordLatency() async -> Int? {
        // Use Discord Status API or Gateway as a reliable endpoint with low overhead
        guard let url = URL(string: "https://discord.com/api/v9/gateway") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // We only need headers, not body
        request.timeoutInterval = 5.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let start = Date()
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, 
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let duration = Date().timeIntervalSince(start)
            let latencyMs = Int(duration * 1000)
            
            return latencyMs
        } catch {
            return nil
        }
    }
}
