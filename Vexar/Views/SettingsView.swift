import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homebrewManager: HomebrewManager
    @Environment(\.dismiss) private var dismiss
    
    // Dynamic Height State
    @State private var contentHeight: CGFloat = 430
    
    // Animation
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // 1. Shared Living Background
            AnimatedMeshBackground(statusColor: .vexarBlue, isVisible: true)
            
            // 2. Glass Overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {


                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(appearAnimation ? 360 : 0))
                        .animation(.spring(response: 1, dampingFraction: 0.7), value: appearAnimation)
                    
                    Text("AYARLAR")
                        .font(.system(size: 16, weight: .heavy, design: .default)) // Fixed font design
                        .tracking(1)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(20)
                .background(.ultraThinMaterial) // Header glass
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Launch at Login Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GENEL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Başlangıçta Çalıştır")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Bilgisayar açıldığında Vexar otomatik başlar.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                                
                                Spacer()
                                
                                // Sliding Toggle
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        appState.launchAtLogin.toggle()
                                    }
                                } label: {
                                    ZStack {
                                        // Track
                                        Capsule()
                                            .fill(Color.black.opacity(0.4))
                                            .frame(width: 130, height: 36)
                                            .overlay(
                                                Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        // Sliding Knob Container
                                        HStack {
                                            if appState.launchAtLogin {
                                                Spacer()
                                            }
                                            
                                            // Knob
                                            HStack(spacing: 6) {
                                                Image(systemName: appState.launchAtLogin ? "checkmark" : "power")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(appState.launchAtLogin ? "AÇIK" : "KAPALI")
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            }
                                            .foregroundColor(appState.launchAtLogin ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        appState.launchAtLogin ?
                                                        LinearGradient(colors: [.vexarGreen, .vexarGreen.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                                    )
                                                    .shadow(color: appState.launchAtLogin ? .vexarGreen.opacity(0.4) : .black.opacity(0.3), radius: 5)
                                                    .overlay(
                                                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            )
                                            .frame(height: 32)
                                            
                                            if !appState.launchAtLogin {
                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                        .frame(width: 130)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        }

                        
                        // Setup Wizard Button (New)
                        Button {
                            // Reset onboarding flag to show it again
                            UserDefaults.standard.set(false, forKey: "onboardingDismissed")
                            // Refresh installation checks
                            homebrewManager.checkInstallations()
                            // Close settings to reveal main view (which will switch to Onboarding)
                            dismiss()
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.vexarBlue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Kurulum Sihirbazı")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Gerekli bileşenleri tekrar kurun.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())                        
                        // App Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BİLGİ")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            VStack(spacing: 0) {
                                // Version
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.vexarBlue)
                                    Text("Versiyon")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("1.0.0 (Beta)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                                
                                Divider().background(.white.opacity(0.1))
                                
                                // SpoofDPI Status
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundColor(.vexarGreen)
                                    Text("Eklenti Durumu")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(homebrewManager.isSpoofDPIInstalled ? Color.vexarGreen : Color.vexarOrange)
                                            .frame(width: 6, height: 6)
                                        Text(homebrewManager.isSpoofDPIInstalled ? "YÜKLÜ" : "YOK")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(homebrewManager.isSpoofDPIInstalled ? .vexarGreen : .vexarOrange)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(6)
                                }
                                .padding(16)
                            }
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Branding Section
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Geliştirici")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("ConsolAktif")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            
                            Link(destination: URL(string: "https://www.youtube.com/@ConsolAktif")!) {
                                HStack {
                                    Image(systemName: "play.rectangle.fill")
                                    Text("YouTube'da Takip Et")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [.red.opacity(0.9), .red.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                )
                                .cornerRadius(12)
                                .shadow(color: .red.opacity(0.4), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                        .background(
                            ZStack {
                                Color.black.opacity(0.3)
                                RadialGradient(colors: [.vexarBlue.opacity(0.1), .clear], center: .center, startRadius: 0, endRadius: 100)
                            }
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                        )
                    }
                    .padding(20)
                    .readHeight { height in
                        // Reuse resizing logic
                        let newHeight = height + 80
                        if abs(contentHeight - newHeight) > 1 {
                             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                 withAnimation { contentHeight = newHeight }
                             }
                        }
                    }
                }
            }
        }
        // Height Preference Emit
        .background(GeometryReader { _ in
            Color.clear.preference(key: ViewHeightKey.self, value: min(contentHeight, 600))
        })
        .preferredColorScheme(.dark)
        .onAppear {
            appearAnimation = true
        }
    }
    

}
