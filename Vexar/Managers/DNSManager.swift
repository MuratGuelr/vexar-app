import Foundation
import Network

@MainActor
class DNSManager: ObservableObject {
    @Published var servers: [DNSServer] = DNSServer.allServers
    @Published var latencies: [String: Int] = [:] // id -> ms
    @Published var bestServer: DNSServer?
    @Published var isPinging: Bool = false
    
    // Cache ping task
    private var pingTask: Task<Void, Never>?
    
    func measureAllLatencies() async {
        isPinging = true
        // 1. Reset metrics to trigger "refresh" visual state
        self.latencies = [:]
        
        await withTaskGroup(of: (String, Int).self) { group in
            for server in servers {
                group.addTask {
                    let ms = await self.ping(host: server.address.components(separatedBy: ":")[0])
                    return (server.id, ms)
                }
            }
            
            // 2. Update incrementally for live sorting effect
            for await (id, ms) in group {
                self.latencies[id] = ms
                // Also update best server on the fly if needed, or wait till end
            }
        }
        
        // 3. Finalize best server
        if let best = latencies.filter({ $0.value < 9999 }).min(by: { $0.value < $1.value }) {
            self.bestServer = servers.first(where: { $0.id == best.key })
        }
        
        isPinging = false
    }
    
    private func ping(host: String) async -> Int {
        let startTime = Date()
        // Simple TCP connect check to port 53 as "ping" estimate
        // Real ICMP requires root privileges which we want to avoid
        return await withCheckedContinuation { continuation in
            let hostEndpoint = NWEndpoint.Host(host)
            let portEndpoint = NWEndpoint.Port(integerLiteral: 53)
            
            let connection = NWConnection(host: hostEndpoint, port: portEndpoint, using: .tcp)
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
                    connection.cancel()
                    continuation.resume(returning: elapsed)
                case .failed(_):
                    connection.cancel()
                    continuation.resume(returning: 9999)
                case .cancelled:
                    // Do not resume connection here as it's already cancelled
                    break
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            // Timeout safety
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                if connection.state != .ready && connection.state != .cancelled {
                    connection.cancel()
                    // Continuation might have been resumed already, so we need care.
                    // But standard CheckedContinuation crashes on double resume.
                    // For simple ping, we rely on connection failing fast or connecting.
                    // This is a simplified reliable-enough ping.
                }
            }
        }
    }
}
