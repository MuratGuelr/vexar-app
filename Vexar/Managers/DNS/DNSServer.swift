import Foundation

struct DNSServer: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let address: String
    let description: String
    
    // UI Helpers
    var displayName: String { name }
    
    static let allServers: [DNSServer] = [
        DNSServer(id: "cloudflare", name: "Cloudflare", address: "1.1.1.1:53", description: "Hızlı ve Gizli"),
        DNSServer(id: "google", name: "Google", address: "8.8.8.8:53", description: "Güvenilir"),
        DNSServer(id: "quad9", name: "Quad9", address: "9.9.9.9:53", description: "Güvenlik Odaklı"),
        DNSServer(id: "adguard", name: "AdGuard", address: "94.140.14.14:53", description: "Reklam Engelleyici"),
        DNSServer(id: "cisco", name: "OpenDNS", address: "208.67.222.222:53", description: "Cisco Güvencesi")
    ]
    
    static let automatic = DNSServer(id: "auto", name: "Otomatik (En Hızlı)", address: "", description: "En iyi sunucuyu seçer")
    
    // Default fallback
    static let defaultServer = allServers[0] // Cloudflare
}
