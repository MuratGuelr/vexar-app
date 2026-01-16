import SwiftUI
import ServiceManagement
import UserNotifications
import FirebaseCore

@main
struct VexarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var homebrewManager = HomebrewManager.shared
    
    init() {
        // Register defaults
        UserDefaults.standard.register(defaults: ["isAnalyticsEnabled": true])
        FirebaseApp.configure()
        requestNotificationPermission()
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appState)
                .environmentObject(homebrewManager)
                .onAppear {
                    sendLaunchNotification()
                    TelemetryManager.shared.sendEvent(eventName: "app_launched")
                }
        } label: {
            HStack(spacing: 4) {
                Image("MenuBarIcon") 
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            }
            .foregroundStyle(appState.isConnected ? .green : .secondary)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func sendLaunchNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Vexar Çalışıyor"
        content.body = "Uygulama menü çubuğunda aktif. Kontrol etmek için ikona tıklayın."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "launch_notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var quittingWindow: NSWindow?
    var splashWindow: NSWindow?
    var uninstallWindow: NSWindow?
    var wizardWindow: NSWindow?
    var isCleaningUp = false
    
    // ... (existing code)
    
    @MainActor
    func showUninstallWindow() {
        // If already open, bring to front
        if let window = uninstallWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.level = .modalPanel // Show above standard windows but typically below screensaver/lock (floating might be too high if we want modal feel)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true // Let user move it if needed? Or false like others.
        window.isReleasedWhenClosed = false
        
        // Ensure it appears on active space
        // window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // Sometimes this behaves weirdly if not fullscreen.
        // Let's rely on standard behavior first, or keep it if we want it over others.
        // Actually, for a modal-like tool, standard behavior is fine, but we want to make sure it's visible.
        
        let mainView = UninstallingView() { [weak self] in
            // Close callback
            self?.closeUninstallWindow()
        }
        
        let manager = HomebrewManager.shared
        
        let hostingView = NSHostingView(rootView: 
            mainView.environmentObject(manager)
        )
        window.contentView = hostingView
        
        // CRITICAL: Bring app to front and show window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        self.uninstallWindow = window
    }
    
    func closeUninstallWindow() {
        guard let window = uninstallWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.close()
            self.uninstallWindow = nil
        })
    }

    @MainActor
    func showWizardWindow() {
        if let window = wizardWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.level = .modalPanel
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let manager = HomebrewManager.shared
        
        // Pass shared AppState to ensure consistent state
        let mainView = WizardWindow(onClose: { [weak self] in
            self?.closeWizardWindow()
        })
        .environmentObject(AppState.shared)
        .environmentObject(manager)
        
        let hostingView = NSHostingView(rootView: mainView)
        window.contentView = hostingView
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        self.wizardWindow = window
    }
    
    func closeWizardWindow() {
        guard let window = wizardWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.close()
            self.wizardWindow = nil
        })
    }
    
    // ...
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Observer for custom window commands
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenUninstallWindow"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.showUninstallWindow()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenWizardWindow"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.showWizardWindow()
            }
        }
        
        showSplashScreen()
        
        // Auto-launch Wizard if not onboarded
        let onboardingDismissed = UserDefaults.standard.bool(forKey: "onboardingDismissed")
        if !onboardingDismissed {
            // Wait for splash (1.5s) + small buffer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                Task { @MainActor in
                    self?.showWizardWindow()
                }
            }
        }
    }
    
    private func showSplashScreen() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 260),
            styleMask: [.borderless], // Borderless for custom shape
            backing: .buffered,
            defer: false
        )
        window.center()
        window.level = .floating // Show above other windows
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isReleasedWhenClosed = false // Manage lifecycle manually
        
        // Ensure it appears on active space
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: SplashScreenView())
        window.contentView = hostingView
        
        window.makeKeyAndOrderFront(nil)
        self.splashWindow = window
        
        // Auto-close after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.closeSplashScreen()
        }
    }
    
    private func closeSplashScreen() {
        guard let window = splashWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.close()
            self.splashWindow = nil
        })
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isCleaningUp {
            return .terminateNow
        }
        
        // 1. Show Quitting UI
        showQuittingWindow()
        
        // 2. Start Cleanup
        isCleaningUp = true
        Task {
            await cleanup()
            
            // 3. Continue Termination after a brief delay for UX
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1s delay
            await MainActor.run {
                sender.terminate(self)
            }
        }
        
        return .terminateCancel
    }
    
    private func showQuittingWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 250),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        let hostingView = NSHostingView(rootView: QuittingView().environmentObject(MainActor.assumeIsolated { AppState.shared }))
        window.contentView = hostingView
        
        window.makeKeyAndOrderFront(nil)
        self.quittingWindow = window
    }
    
    @MainActor
    private func cleanup() async {
        // Step 1
        withAnimation { AppState.shared.quittingStatus = String(localized: "status_cleaning") }
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // Step 2
        withAnimation { AppState.shared.quittingStatus = String(localized: "status_stopping_service") }
        AppState.shared.processManager.stopBlocking()
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        
        // Step 3
        withAnimation { AppState.shared.quittingStatus = String(localized: "status_cleanup_temp") }
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        
        // Step 4
        TelemetryManager.shared.sendEvent(eventName: "app_quit")
        withAnimation { AppState.shared.quittingStatus = String(localized: "status_goodbye") }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
    }
}

/// Content wrapper to handle onboarding
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homebrewManager: HomebrewManager
    
    // We no longer rely on ContentView to show onboarding. 
    // AppDelegate handles it via WizardWindow.
    
    var body: some View {
        MenuBarView()
            .environmentObject(appState)
            .environmentObject(homebrewManager)
            .sheet(isPresented: $appState.updateManager.isUpdateAvailable) {
                UpdateView()
                    .environmentObject(appState.updateManager)
            }
    }
}

// MARK: - Vexar Theme Colors

extension Color {
    static let vexarBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let vexarOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    static let vexarGreen = Color(red: 0.2, green: 0.9, blue: 0.4)
    static let vexarGrey = Color(white: 0.4)
    static let vexarBackground = Color(red: 0.08, green: 0.08, blue: 0.1)
    static let vexarCardBackground = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let vexarDivider = Color(white: 0.2)
}

// MARK: - View Height Helper

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func readHeight(onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewHeightKey.self, value: geometry.size.height)
            }
        )
        .onPreferenceChange(ViewHeightKey.self, perform: onChange)
    }
}

