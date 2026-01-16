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
                    
                    Text(String(localized: "settings_title"))
                        .font(.system(size: 16, weight: .heavy, design: .default)) // Fixed font design
                        .tracking(1)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(20)
                .background(.ultraThinMaterial) // Header glass
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Setup Wizard Button (Moved to Top)
                        Button {
                            UserDefaults.standard.set(false, forKey: "onboardingDismissed")
                            // homebrewManager.checkInstallations() // Will be done in WizardWindow
                            dismiss()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NotificationCenter.default.post(name: NSNotification.Name("OpenWizardWindow"), object: nil)
                            }
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
                                    Text(String(localized: "setup_wizard"))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(String(localized: "setup_wizard_desc"))
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
                        
                        
                        // Launch at Login Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "section_general"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "launch_at_login"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(String(localized: "launch_at_login_desc"))
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
                                                Text(appState.launchAtLogin ? String(localized: "on") : String(localized: "off"))
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
                        
                        // Auto Connect Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "section_automation"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "auto_connect"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(String(localized: "auto_connect_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                                
                                // Sliding Toggle
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        appState.autoConnect.toggle()
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
                                            if appState.autoConnect {
                                                Spacer()
                                            }
                                            
                                            // Knob
                                            HStack(spacing: 6) {
                                                Image(systemName: appState.autoConnect ? "bolt.fill" : "bolt.slash.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(appState.autoConnect ? String(localized: "on") : String(localized: "off"))
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            }
                                            .foregroundColor(appState.autoConnect ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        appState.autoConnect ?
                                                        LinearGradient(colors: [.vexarOrange, .vexarOrange.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                                    )
                                                    .shadow(color: appState.autoConnect ? .vexarOrange.opacity(0.4) : .black.opacity(0.3), radius: 5)
                                                    .overlay(
                                                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            )
                                            .frame(height: 32)
                                            
                                            if !appState.autoConnect {
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

                        // DNS Optimization Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("DNS Listesi")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        // 1. Measure
                                        await appState.dnsManager.measureAllLatencies()
                                        
                                        // 2. Smart Reconnect if in Auto Mode to apply new best server
                                        if appState.isAutoDNS && appState.isConnected {
                                            appState.disconnect()
                                            try? await Task.sleep(nanoseconds: 500_000_000)
                                            appState.connect()
                                        }
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(4)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                        .rotationEffect(.degrees(appState.dnsManager.isPinging ? 360 : 0))
                                        .animation(appState.dnsManager.isPinging ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.dnsManager.isPinging)
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.dnsManager.isPinging)
                            }
                            
                            // Auto Connect Section Style for "Auto Choice"
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Otomatik Seçim")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("En düşük gecikmeli sunucuyu kullanır")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                                
                                // Sliding Toggle (Consistency)
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        appState.isAutoDNS.toggle()
                                        if appState.isConnected {
                                            Task {
                                                appState.disconnect()
                                                try? await Task.sleep(nanoseconds: 500_000_000)
                                                appState.connect()
                                            }
                                        }
                                        // If turned on, re-measure to ensure best is fresh
                                        if appState.isAutoDNS {
                                            Task { await appState.dnsManager.measureAllLatencies() }
                                        }
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
                                            if appState.isAutoDNS {
                                                Spacer()
                                            }
                                            
                                            // Knob
                                            HStack(spacing: 6) {
                                                Image(systemName: appState.isAutoDNS ? "bolt.fill" : "slider.horizontal.3")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(appState.isAutoDNS ? String(localized: "on") : String(localized: "off"))
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            }
                                            .foregroundColor(appState.isAutoDNS ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        appState.isAutoDNS ?
                                                        LinearGradient(colors: [.vexarGreen, .vexarGreen.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                                    )
                                                    .shadow(color: appState.isAutoDNS ? .vexarGreen.opacity(0.4) : .black.opacity(0.3), radius: 5)
                                                    .overlay(
                                                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            )
                                            .frame(height: 32)
                                            
                                            if !appState.isAutoDNS {
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
                            
                            // DNS List (Always Visible)
                            VStack(spacing: 4) {
                                let sortedServers = appState.dnsManager.servers.sorted { s1, s2 in
                                    let l1 = appState.dnsManager.latencies[s1.id] ?? 9999
                                    let l2 = appState.dnsManager.latencies[s2.id] ?? 9999
                                    // If auto is ON, we might want to stabilize sort if pings fluctuate? 
                                    // No, user wants sort by ms.
                                    return l1 < l2
                                }
                                
                                ForEach(sortedServers) { server in
                                    let isSelected = appState.isAutoDNS ? (appState.dnsManager.bestServer?.id == server.id) : (appState.selectedDNSID == server.id)
                                    
                                    Button(action: {
                                        withAnimation {
                                            appState.selectedDNSID = server.id
                                            if appState.isConnected {
                                                    Task {
                                                        appState.disconnect()
                                                        try? await Task.sleep(nanoseconds: 500_000_000)
                                                        appState.connect()
                                                    }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            // Radio Circle
                                            ZStack {
                                                Circle()
                                                    .strokeBorder(isSelected ? (appState.isAutoDNS ? Color.vexarGreen : Color.vexarBlue) : Color.white.opacity(0.2), lineWidth: 2)
                                                    .frame(width: 16, height: 16)
                                                
                                                if isSelected {
                                                    Circle()
                                                        .fill(appState.isAutoDNS ? Color.vexarGreen : Color.vexarBlue)
                                                        .frame(width: 8, height: 8)
                                                }
                                            }
                                                
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(server.name)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .opacity(appState.isAutoDNS && !isSelected ? 0.5 : 1)
                                                Text(server.description)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            
                                            Spacer()
                                            
                                            // Latency Badge
                                            if appState.dnsManager.isPinging && appState.dnsManager.latencies[server.id] == nil {
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                                    .frame(width: 40)
                                            } else if let ms = appState.dnsManager.latencies[server.id] {
                                                Text("\(ms)ms")
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(ms < 50 ? Color.green.opacity(0.2) : (ms < 150 ? Color.yellow.opacity(0.2) : Color.red.opacity(0.2)))
                                                    )
                                                    .foregroundColor(ms < 50 ? .green : (ms < 150 ? .yellow : .red))
                                            } else {
                                                Text("-")
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(.white.opacity(0.3))
                                                    .frame(width: 40)
                                            }
                                        }
                                        .padding(10)
                                        .background(isSelected ? (appState.isAutoDNS ? Color.vexarGreen.opacity(0.1) : Color.vexarBlue.opacity(0.1)) : Color.clear)
                                        .cornerRadius(8)
                                        .contentShape(Rectangle()) // Better tap area
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(appState.isAutoDNS) // Disable manual selection if Auto is ON
                                    .opacity(appState.isAutoDNS && !isSelected ? 0.6 : 1) // Dim unselected items in Auto mode
                                }
                            }
                            .padding(4)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.dnsManager.latencies)
                        }
                        
                        // Privacy Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "section_privacy"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "analytics_title"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(String(localized: "analytics_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                
                                // Analytic Toggle
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        appState.isAnalyticsEnabled.toggle()
                                        if appState.isAnalyticsEnabled {
                                            TelemetryManager.shared.sendEvent(eventName: "analytics_opt_in")
                                        }
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
                                            if appState.isAnalyticsEnabled {
                                                Spacer()
                                            }
                                            
                                            // Knob
                                            HStack(spacing: 6) {
                                                Image(systemName: appState.isAnalyticsEnabled ? "chart.bar.fill" : "chart.bar")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(appState.isAnalyticsEnabled ? String(localized: "on") : String(localized: "off"))
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            }
                                            .foregroundColor(appState.isAnalyticsEnabled ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        appState.isAnalyticsEnabled ?
                                                        LinearGradient(colors: [.vexarBlue, .vexarBlue.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                                    )
                                                    .shadow(color: appState.isAnalyticsEnabled ? .vexarBlue.opacity(0.4) : .black.opacity(0.3), radius: 5)
                                                    .overlay(
                                                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            )
                                            .frame(height: 32)
                                            
                                            if !appState.isAnalyticsEnabled {
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

                        


                            

                            
                            // Developer Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(localized: "section_developer"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                VStack(spacing: 16) {
                                    // Profile Header
                                    HStack(spacing: 14) {
                                        AsyncImage(url: URL(string: "https://yt3.ggpht.com/M-YH7dPjl40d2cXHK30at3hYyn1seO_RO4MJ-ee8FMN6wHrRQ6ZVaX48JIwHt0BqZSA3do8N2g=s88-c-k-c0x00ffffff-no-rj")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            ZStack {
                                                Circle()
                                                    .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                        .shadow(color: .red.opacity(0.4), radius: 6)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(String(localized: "developer_name"))
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text(String(localized: "developer_title"))
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Subscribe Button
                                    Button {
                                        if let url = URL(string: "https://www.youtube.com/@ConsolAktif/videos") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "play.rectangle.fill")
                                                .font(.system(size: 16))
                                                Text(String(localized: "subscribe_youtube"))
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(red: 0.9, green: 0, blue: 0)) // YouTube Red
                                                .shadow(color: .red.opacity(0.4), radius: 5, y: 2)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                .padding(16)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                            
                            // Danger Zone
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(localized: "section_danger_zone"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red.opacity(0.5))
                                
                                Button {
                                    // Close settings and show uninstall window
                                    dismiss()
                                    // Post notification to open window
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        NotificationCenter.default.post(name: NSNotification.Name("OpenUninstallWindow"), object: nil)
                                    }
                                } label: {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red.opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.red)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(String(localized: "uninstall_app"))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.red)
                                            Text(String(localized: "uninstall_desc"))
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red.opacity(0.5))
                                    }
                                    .padding(12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        } // End VStack
                        .padding(20)
                        .readHeight { height in
                            if height > 0 {
                                contentHeight = min(height + 80, 600)
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
            appState.checkLaunchAtLoginStatus()
            // Initial ping
            Task {
                await appState.dnsManager.measureAllLatencies()
            }
        }
    }
}
