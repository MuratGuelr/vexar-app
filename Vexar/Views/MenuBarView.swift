import SwiftUI

// MARK: - Vexar 1.0 Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homebrewManager: HomebrewManager
    
    // Window Management
    @State private var windowHeight: CGFloat = 520
    
    // Animation States
    @State private var isVisible: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Living Background
                AnimatedMeshBackground(statusColor: statusColor, isVisible: isVisible)
                
                // 2. Glass Overlay (Frosted effect)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
                
                // 3. Main Content
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image("VexarLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .shadow(color: statusColor.opacity(0.5), radius: 8)
                        
                        Text("VEXAR")
                            .font(.system(size: 14, weight: .heavy, design: .default))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        // Status Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                                .shadow(color: statusColor, radius: 4)
                            
                            Text(statusText.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(statusColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.1))
                                .overlay(Capsule().stroke(statusColor.opacity(0.2), lineWidth: 1))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    Spacer()
                    
                    // Core Reactor (Centerpiece)
                    PulseCoreView(
                        isConnected: appState.isConnected,
                        isConnecting: appState.isConnecting,
                        color: statusColor,
                        isVisible: isVisible
                    )
                    .frame(height: 220)
                    .contentShape(Rectangle()) // Hit testing area
                    .onTapGesture {
                        toggleConnection()
                    }
                    .drawingGroup() // Offload composite rendering to GPU
                    
                    Spacer()
                    
                    // Warning Banner (if needed)
                    if !homebrewManager.isSpoofDPIInstalled {
                        Text("⚠️ SpoofDPI Bulunamadı")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.vexarOrange)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }
                    
                    // Connect Button
                    Button(action: toggleConnection) {
                        HStack {
                            Image(systemName: "power")
                            .font(.system(size: 20, weight: .bold))
                            Text(appState.isConnected ? "BAĞLANTIYI KES" : "BAĞLAN")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(appState.isConnected ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                if appState.isConnected {
                                    Color.red.opacity(0.8)
                                } else {
                                    Color.white
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(
                            color: (appState.isConnected ? Color.red : Color.white).opacity(0.3),
                            radius: 20, y: 5
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .disabled(appState.isConnecting)
                    
                    // Bottom Navigation Bar
                    HStack(spacing: 0) {
                        NavButton(icon: "gearshape.fill", label: "AYARLAR", destination: "settings")
                        
                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.1))
                        
                        NavButton(icon: "doc.text.fill", label: "LOGLAR", destination: "logs")
                        
                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.1))
                        
                        Button {
                            NSApplication.shared.terminate(nil)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "power")
                                    .font(.system(size: 16))
                                Text("ÇIKIŞ")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(Color.black.opacity(0.2))
                }
            }
            // Emit natural height preference
            .background(GeometryReader { geometry in
                Color.clear.preference(key: ViewHeightKey.self, value: geometry.size.height)
            })
            // Configure Navigation
            .navigationDestination(for: String.self) { destination in
                if destination == "settings" {
                    SettingsView()
                        .environmentObject(appState)
                        .environmentObject(homebrewManager)
                } else if destination == "logs" {
                    LogsView().environmentObject(appState)
                }
            }
        }
        .frame(width: 350, height: windowHeight)
        .preferredColorScheme(.dark)
        // Listen to preference changes for resizing
        .onPreferenceChange(ViewHeightKey.self) { height in
            if height > 0 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    windowHeight = height
                }
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
    
    // Logic
    func toggleConnection() {
        let impact = NSHapticFeedbackManager.defaultPerformer
        impact.perform(.alignment, performanceTime: .default)
        
        if appState.isConnected {
            withAnimation { appState.disconnect() }
        } else {
            withAnimation { appState.connect() }
        }
    }
    
    var statusColor: Color {
        if appState.isConnecting { return .vexarOrange }
        if appState.isConnected { return .vexarGreen }
        return .vexarBlue
    }
    
    var statusText: String {
        if appState.isConnecting { return "Bağlanıyor..." }
        if appState.isConnected { return "Güvenli" }
        return "Pasif"
    }
}

// MARK: - Components

struct PulseCoreView: View {
    let isConnected: Bool
    let isConnecting: Bool
    let color: Color
    var isVisible: Bool // Gating binding
    
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            
            // Core
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(color.opacity(0.5), lineWidth: 1)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: isConnected ? "shield.fill" : "shield.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(color)
                        .shadow(color: color, radius: 10)
                        .scaleEffect(pulse)
                }
                
                VStack(spacing: 4) {
                    Text(isConnected ? "GÜVENLİ" : (isConnecting ? "BAĞLANIYOR..." : "HAZIR"))
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.5), radius: 6)
                    
                    Text(isConnected ? "Discord'u sorunsuzca kullanabilirsiniz." : "DPI Bypass için bağlanın.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(width: 200)
                }
                .offset(y: 10)
            }
        }
        .onAppear {
            if isVisible {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        pulse = 1.1
                    }
                }
            }
        }
    }
}

struct AnimatedMeshBackground: View { // Renamed internally to ModernBackground but kept name to avoid breaking other files
    let statusColor: Color
    var isVisible: Bool // Kept for compatibility but unused
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Premium Static Gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    statusColor.opacity(0.15),
                    statusColor.opacity(0.05),
                    Color.black
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            // Subtle Noise Texture (Optional, for premium feel)
            Rectangle()
                .fill(.white.opacity(0.02))
                .blendMode(.overlay)
        }
    }
}

struct NavButton: View {
    let icon: String
    let label: String
    let destination: String
    
    var body: some View {
        NavigationLink(value: destination) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
        .environmentObject(HomebrewManager())
}
