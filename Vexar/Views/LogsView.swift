import SwiftUI

struct LogsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var contentHeight: CGFloat = 200
    
    var body: some View {
        ZStack {
            // 1. Shared Living Background
            AnimatedMeshBackground(statusColor: .vexarOrange, isVisible: true) // Orange for "Debug/Logs" vibe
            
            // 2. Glass Overlay (Darker for readability)
            Rectangle()
                .fill(.black.opacity(0.4))
                .ignoresSafeArea()
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.vexarOrange)
                    
                    Text("SİSTEM LOGLARI")
                        .font(.system(size: 14, weight: .heavy, design: .default))
                        .tracking(1)
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(16)
                .background(.ultraThinMaterial)
                
                // Logs Console
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(appState.logs.enumerated()), id: \.offset) { index, message in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(String(format: "%03d", index + 1))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.2))
                                        .frame(width: 24, alignment: .trailing)
                                    
                                    Text(message)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(logColor(for: message))
                                        .shadow(color: logColor(for: message).opacity(0.3), radius: 2)
                                }
                                .padding(.horizontal, 4)
                                .id(index)
                            }
                        }
                        .padding(16)
                        // Dynamic Resizing Logic
                        .readHeight { height in
                            let newHeight = height + 100
                            if abs(contentHeight - newHeight) > 1 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation { contentHeight = newHeight }
                                }
                            }
                        }
                    }
                    .onChange(of: appState.logs.count) { count in
                        if count > 0 {
                            withAnimation {
                                proxy.scrollTo(count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Footer
                HStack {
                    Button(action: { appState.clearLogs() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("TEMİZLE")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(8)
                        .padding(.horizontal, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        let text = appState.logs.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("KOPYALA")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(8)
                        .padding(.horizontal, 4)
                        .background(Color.vexarBlue.opacity(0.2))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.vexarBlue.opacity(0.3)))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.vexarBlue)
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
        }
        // Emit Height Preference
        .background(GeometryReader { _ in
            Color.clear.preference(key: ViewHeightKey.self, value: min(max(contentHeight, 300), 550))
        })
        .preferredColorScheme(.dark)
    }
    
    private func logColor(for message: String) -> Color {
        if message.contains("error") || message.contains("fail") || message.contains("❌") { return .red }
        if message.contains("warn") || message.contains("⚠️") { return .orange }
        if message.contains("success") || message.contains("connected") || message.contains("✅") { return .green }
        return .white.opacity(0.8)
    }
}
