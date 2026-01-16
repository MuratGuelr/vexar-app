import SwiftUI

struct WizardWindow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homebrewManager: HomebrewManager
    
    // Window control callback
    var onClose: () -> Void
    
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedMeshBackground(statusColor: .vexarBlue, isVisible: true)
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()
            
            // Border
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                
            // Content
            OnboardingView(isPresented: .constant(true), onFinish: onClose)
                .environmentObject(appState)
                .environmentObject(homebrewManager)
                .padding()
        }
        .frame(width: 350, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            withAnimation {
                appearAnimation = true
            }
        }
    }
}
