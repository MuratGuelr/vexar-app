import SwiftUI

struct QuittingView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulse = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            // Mesh Gradient simulation
            LinearGradient(
                colors: [Color.vexarBlue.opacity(0.1), Color.purple.opacity(0.05)],
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
                        .fill(Color.vexarOrange.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .stroke(Color.vexarOrange.opacity(0.3), lineWidth: 1)
                        .frame(width: 70, height: 70)
                        .scaleEffect(pulse ? 1.2 : 0.8)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                    
                    Image(systemName: "power")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.vexarOrange)
                        .shadow(color: Color.vexarOrange.opacity(0.5), radius: 10)
                }
                
                VStack(spacing: 8) {
                    Text(String(localized: "quitting_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Dynamic Status Text
                    Text(appState.quittingStatus)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(height: 20) // fixed height to prevent jump
                        .transition(.opacity)
                        .id(appState.quittingStatus) // trigger transition on change
                }
                
                // Progress Bar
                VStack(spacing: 4) {
                    ProgressView()
                        .tint(.vexarOrange)
                        .scaleEffect(0.8)
                }
            }
            .padding(32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)
        }
        .frame(width: 320, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            pulse = true
            withAnimation(.spring(duration: 0.5)) {
                showContent = true
            }
        }
    }
}
