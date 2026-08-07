import SwiftUI
import AppKit

public enum HUDState {
    case processing
    case success(String)
    case error(String)
}

public struct HUDView: View {
    let state: HUDState
    
    public var body: some View {
        HStack(spacing: 10) {
            switch state {
            case .processing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.85)
            case .success(let message):
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 1)
        )
        .padding(20)
    }
}
