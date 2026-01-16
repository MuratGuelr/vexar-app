import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Premium Gradient Background
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.vexarBlue.opacity(0.2),
                    Color.purple.opacity(0.1),
                    Color.black
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Border
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            
            VStack(spacing: 20) {
                // Logo Animation
                ZStack {
                    // Outer glow rings
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.vexarBlue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(isAnimating ? 1.1 + CGFloat(i) * 0.1 : 0.8)
                            .opacity(isAnimating ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: isAnimating
                            )
                    }
                    
                    // Main Logo Container
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vexarBlue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // Static Icon
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .shadow(color: .vexarBlue.opacity(0.6), radius: 10)
                }
                .scaleEffect(isAnimating ? 1 : 0.5)
                .opacity(opacity)
                
                // Text
                VStack(spacing: 6) {
                    Text("VEXAR")
                        .font(.system(size: 24, weight: .heavy, design: .default))
                        .tracking(8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text(String(localized: "system_ready"))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                }
                .opacity(opacity)
                .offset(y: isAnimating ? 0 : 20)
            }
        }
        .frame(width: 320, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            // Intro Animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                opacity = 1.0
                isAnimating = true
            }
        }
    }
}
