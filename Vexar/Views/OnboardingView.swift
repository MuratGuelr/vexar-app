import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homebrewManager: HomebrewManager
    @Binding var isPresented: Bool
    var onFinish: (() -> Void)? = nil
    
    @State private var showError = false
    @State private var isDiscordInstalled = false
    @State private var appearAnimation = false
    @State private var animateBg = false
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground(statusColor: Color.vexarBlue, isVisible: true)
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
                headerSection
                    .offset(y: appearAnimation ? 0 : 30)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                
                statusSection
                    .offset(y: appearAnimation ? 0 : 40)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                
                actionSection
                    .offset(y: appearAnimation ? 0 : 50)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 350, height: 520)
        .preferredColorScheme(.dark)
        .alert(String(localized: "install_failed"), isPresented: $showError) {
            Button(String(localized: "ok"), role: .cancel) {}
        } message: {
            Text(homebrewManager.installError ?? "")
        }
        .onAppear {
            homebrewManager.checkInstallations()
            checkDiscord()
            
            withAnimation {
                appearAnimation = true
                animateBg = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.vexarBlue.opacity(0.6), radius: 10)
            }
            .padding(.top, 0)
            
            VStack(spacing: 4) {
                Text("VEXAR")
                    .font(.system(size: 18, weight: .heavy, design: .default))
                    .tracking(2)
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.1), radius: 8)
                
                Text(String(localized: "version"))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            .background(Color.black.opacity(0.3).cornerRadius(20))
                    )
            }
            
            Text(String(localized: "welcome_desc"))
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 9))
                Text(homebrewManager.cpuArchitecture.displayName.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundColor(Color.vexarBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.vexarBlue.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vexarBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            statusRow(
                icon: "cube.box.fill",
                iconColor: Color.vexarGreen,
                title: "Homebrew",
                subtitle: homebrewManager.isHomebrewInstalled ? String(localized: "installed") : String(localized: "homebrew_not_found"),
                isInstalled: homebrewManager.isHomebrewInstalled
            )
            
            statusRow(
                icon: "network.badge.shield.half.filled",
                iconColor: Color.vexarBlue,
                title: "SpoofDPI",
                subtitle: homebrewManager.isSpoofDPIInstalled ? String(localized: "installed") : String(localized: "spoofdpi_not_found"),
                isInstalled: homebrewManager.isSpoofDPIInstalled
            )
            
            statusRow(
                icon: "gamecontroller.fill",
                iconColor: .purple,
                title: "Discord",
                subtitle: isDiscordInstalled ? String(localized: "installed") : String(localized: "not_found"),
                isInstalled: isDiscordInstalled
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.1), .white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func checkDiscord() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.hnc.Discord") {
             isDiscordInstalled = FileManager.default.fileExists(atPath: url.path)
        } else {
             isDiscordInstalled = FileManager.default.fileExists(atPath: "/Applications/Discord.app")
        }
    }
    
    private func statusRow(icon: String, iconColor: Color, title: String, subtitle: String, isInstalled: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isInstalled ? iconColor.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isInstalled ? iconColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: isInstalled ? iconColor.opacity(0.4) : .clear, radius: 8)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isInstalled ? iconColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(isInstalled ? Color.vexarGreen : .secondary)
            }
            
            Spacer()
            
            if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.vexarGreen)
                    .shadow(color: Color.vexarGreen.opacity(0.5), radius: 6)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.vexarOrange)
                    .opacity(0.7)
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if homebrewManager.isInstalling {
                VStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                    Text(homebrewManager.installProgress)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 2)
                .transition(.opacity)
            }
            
            mainActionButton
            secondaryActions
        }
    }
    
    @ViewBuilder
    private var mainActionButton: some View {
        if homebrewManager.isSpoofDPIInstalled && isDiscordInstalled {
            Button(action: dismissOnboarding) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(String(localized: "complete_setup"))
                }
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.vexarGreen, Color.vexarGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.vexarGreen.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            
        } else if !homebrewManager.isHomebrewInstalled {
            Button(action: {
                Task {
                    await homebrewManager.openTerminalForHomebrew()
                }
            }) {
                HStack(spacing: 8) {
                    if homebrewManager.isInstalling {
                        ProgressView().scaleEffect(0.5).tint(.white)
                    } else {
                        Image(systemName: "terminal.fill")
                    }
                    Text(String(localized: "install_homebrew"))
                }
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.vexarOrange, Color.vexarOrange.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.vexarOrange.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(homebrewManager.isInstalling)
            .opacity(homebrewManager.isInstalling ? 0.7 : 1)
            
        } else if !homebrewManager.isSpoofDPIInstalled {
            Button(action: installSpoofDPI) {
                HStack(spacing: 8) {
                    if homebrewManager.isInstalling {
                        ProgressView().scaleEffect(0.5).tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(String(localized: "install_spoofdpi"))
                }
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.vexarBlue, Color.vexarBlue.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.vexarBlue.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(homebrewManager.isInstalling)
            .opacity(homebrewManager.isInstalling ? 0.7 : 1)
            
        } else {
            Button(action: installDiscord) {
                HStack(spacing: 8) {
                    if homebrewManager.isInstalling {
                        ProgressView().scaleEffect(0.5).tint(.white)
                    } else {
                        Image(systemName: "gamecontroller.fill")
                    }
                    Text(String(localized: "install_discord"))
                }
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.purple.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(homebrewManager.isInstalling)
            .opacity(homebrewManager.isInstalling ? 0.7 : 1)
        }
    }
    
    private var secondaryActions: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation {
                    homebrewManager.checkInstallations()
                    checkDiscord()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(localized: "refresh_status"))
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.05)))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            if !homebrewManager.isSpoofDPIInstalled {
                Button(action: dismissOnboarding) {
                    Text(String(localized: "skip"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    
    private func installSpoofDPI() {
        Task {
            let success = await homebrewManager.installSpoofDPI()
            if !success && homebrewManager.installError != nil {
                showError = true
            }
        }
    }
    
    private func installDiscord() {
        Task {
            let success = await homebrewManager.installDiscord()
            if !success && homebrewManager.installError != nil {
                showError = true
            }
        }
    }
    
    private func dismissOnboarding() {
        withAnimation {
            UserDefaults.standard.set(true, forKey: "onboardingDismissed")
            isPresented = false
            onFinish?()
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(AppState())
        .environmentObject(HomebrewManager())
}
