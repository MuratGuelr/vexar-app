import SwiftUI

struct UninstallingView: View {
    @EnvironmentObject var homebrewManager: HomebrewManager
    
    // Window control callback
    var onClose: () -> Void
    
    @State private var pulse = false
    @State private var showContent = false
    
    // Uninstall Logic State
    enum UninstallStep {
        case confirmation
        case removingSpoofDPI
        case askDiscord
        case askHomebrew
        case final
    }
    
    @State private var step: UninstallStep = .confirmation
    @State private var statusMessage: String = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            // Mesh Gradient simulation
            LinearGradient(
                colors: [Color.red.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Border
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        .frame(width: 70, height: 70)
                        .scaleEffect(pulse ? 1.2 : 0.8)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.red)
                        .shadow(color: Color.red.opacity(0.5), radius: 10)
                }
                
                // Content
                VStack(spacing: 16) {
                    Text(String(localized: "uninstall_tool_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if step == .confirmation {
                        Text(String(localized: "uninstall_confirmation"))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(height: 40)
                    } else {
                        Text(statusMessage)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(height: 40)
                            .transition(.opacity)
                            .id(statusMessage)
                    }
                }
                .padding(.horizontal)
                
                // Actions
                if step == .removingSpoofDPI || step == .final {
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(1.0)
                } else {
                    HStack(spacing: 20) {
                        // NO Button
                        Button {
                            if step == .confirmation {
                                onClose()
                            } else {
                                handleUninstallChoice(remove: false)
                            }
                        } label: {
                            Text(String(localized: "no"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 36)
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        // YES Button
                        Button {
                            if step == .confirmation {
                                startUninstall()
                            } else {
                                handleUninstallChoice(remove: true)
                            }
                        } label: {
                            Text(String(localized: "yes"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 36)
                                .background(Capsule().fill(Color.red))
                                .shadow(color: .red.opacity(0.4), radius: 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)
        }
        .frame(width: 340, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            pulse = true
            withAnimation(.spring(duration: 0.5)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Logic
    
    func startUninstall() {
        withAnimation {
            step = .removingSpoofDPI
            statusMessage = String(localized: "uninstall_stopping_services")
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            await MainActor.run { statusMessage = String(localized: "uninstall_removing_spoofdpi") }
            _ = await homebrewManager.uninstallSpoofDPI()
            
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            await MainActor.run {
                withAnimation {
                    step = .askDiscord
                    statusMessage = String(localized: "uninstall_ask_discord")
                }
            }
        }
    }
    
    func handleUninstallChoice(remove: Bool) {
        Task {
            if step == .askDiscord {
                if remove {
                    await MainActor.run { statusMessage = String(localized: "uninstall_removing_discord") }
                    _ = await homebrewManager.uninstallDiscord()
                }
                
                await MainActor.run {
                    withAnimation {
                        step = .askHomebrew
                        statusMessage = String(localized: "uninstall_ask_homebrew")
                    }
                }
            } else if step == .askHomebrew {
                if remove {
                    await MainActor.run { statusMessage = String(localized: "uninstall_running_homebrew") }
                    homebrewManager.uninstallHomebrew()
                    try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                }
                
                await MainActor.run {
                    withAnimation {
                        step = .final
                        statusMessage = String(localized: "uninstall_final")
                    }
                }
                
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                homebrewManager.selfDestruct()
            }
        }
    }
}
