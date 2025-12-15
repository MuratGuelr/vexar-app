import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homebrewManager: HomebrewManager
    @Binding var isPresented: Bool
    
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
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
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
            }
        }
        .frame(width: 400, height: 600)
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
        VStack(spacing: 24) {
            ZStack {
                Image("VexarLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.vexarBlue.opacity(0.6), radius: 15)
            }
            .padding(.top, 10)
            
            VStack(spacing: 8) {
                Text("VEXAR")
                    .font(.system(size: 28, weight: .heavy, design: .default))
                    .tracking(2)
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.1), radius: 10)
                
                Text(String(localized: "version"))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            .background(Color.black.opacity(0.3).cornerRadius(20))
                    )
            }
            
            Text("VEXAR ile internet deneyimine başlamak için\ngerekli bileşenleri kuralım.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 10))
                Text(homebrewManager.cpuArchitecture.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(Color.vexarBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.vexarBlue.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vexarBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 16) {
            statusRow(
                icon: "cube.box.fill",
                iconColor: Color.vexarGreen,
                title: "Homebrew",
                subtitle: homebrewManager.isHomebrewInstalled ? "YÜKLÜ" : "Homebrew kurulu değil",
                isInstalled: homebrewManager.isHomebrewInstalled
            )
            
            statusRow(
                icon: "network.badge.shield.half.filled",
                iconColor: Color.vexarBlue,
                title: "SpoofDPI",
                subtitle: homebrewManager.isSpoofDPIInstalled ? "YÜKLÜ" : "SpoofDPI kurulu değil",
                isInstalled: homebrewManager.isSpoofDPIInstalled
            )
            
            statusRow(
                icon: "gamecontroller.fill",
                iconColor: .purple,
                title: "Discord",
                subtitle: isDiscordInstalled ? "YÜKLÜ" : "Discord kurulu değil",
                isInstalled: isDiscordInstalled
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
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
        isDiscordInstalled = FileManager.default.fileExists(atPath: "/Applications/Discord.app")
    }
    
    private func statusRow(icon: String, iconColor: Color, title: String, subtitle: String, isInstalled: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isInstalled ? iconColor.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isInstalled ? iconColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: isInstalled ? iconColor.opacity(0.4) : .clear, radius: 8)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isInstalled ? iconColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isInstalled ? Color.vexarGreen : .secondary)
            }
            
            Spacer()
            
            if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.vexarGreen)
                    .shadow(color: Color.vexarGreen.opacity(0.5), radius: 6)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.vexarOrange)
                    .opacity(0.7)
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 20) {
            if homebrewManager.isInstalling {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text(homebrewManager.installProgress)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 8)
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
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("KURULUMU TAMAMLA")
                }
                .font(.system(size: 14, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [Color.vexarGreen, Color.vexarGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.vexarGreen.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            
        } else if !homebrewManager.isHomebrewInstalled {
            Button(action: {
                homebrewManager.openTerminalForHomebrew()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "terminal.fill")
                    Text("HOMEBREW KUR")
                }
                .font(.system(size: 14, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [Color.vexarOrange, Color.vexarOrange.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.vexarOrange.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            
        } else if !homebrewManager.isSpoofDPIInstalled {
            Button(action: installSpoofDPI) {
                HStack(spacing: 12) {
                    if homebrewManager.isInstalling {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text("SPOOFDPI İNDİR")
                }
                .font(.system(size: 14, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [Color.vexarBlue, Color.vexarBlue.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.vexarBlue.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(homebrewManager.isInstalling)
            .opacity(homebrewManager.isInstalling ? 0.7 : 1)
            
        } else {
            Button(action: installDiscord) {
                HStack(spacing: 12) {
                    if homebrewManager.isInstalling {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    } else {
                        Image(systemName: "gamecontroller.fill")
                    }
                    Text("DISCORD KUR")
                }
                .font(.system(size: 14, weight: .heavy))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .foregroundColor(.white)
                .shadow(color: Color.purple.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(homebrewManager.isInstalling)
            .opacity(homebrewManager.isInstalling ? 0.7 : 1)
        }
    }
    
    private var secondaryActions: some View {
        HStack(spacing: 20) {
            Button(action: {
                withAnimation {
                    homebrewManager.checkInstallations()
                    checkDiscord()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                    Text("Yenile")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.05)))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            if !homebrewManager.isSpoofDPIInstalled {
                Button(action: dismissOnboarding) {
                    Text("Şimdilik Atla")
                        .font(.system(size: 12, weight: .medium))
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
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(AppState())
        .environmentObject(HomebrewManager())
}
