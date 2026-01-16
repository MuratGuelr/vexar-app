import SwiftUI

struct UpdateView: View {
    @EnvironmentObject var updateManager: UpdateManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.vexarBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.vexarBlue, .vexarGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .vexarBlue.opacity(0.5), radius: 10)
                
                VStack(spacing: 8) {
                    Text(String(localized: "update_available_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(String(localized: "update_version_text", defaultValue: "Vexar \(updateManager.latestVersion) is now available."))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // Release Notes
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "update_notes_title"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(updateManager.releaseNotes)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Buttons
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text(String(localized: "update_later"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if let url = updateManager.downloadURL {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text(String(localized: "update_download"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.vexarBlue)
                            .cornerRadius(10)
                            .shadow(color: .vexarBlue.opacity(0.3), radius: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(width: 350, height: 400)
    }
}
