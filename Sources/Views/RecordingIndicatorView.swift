import SwiftUI

struct RecordingIndicatorView: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .scaleEffect(isPulsing ? 1.3 : 0.8)
                .opacity(isPulsing ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)

            Text("Listening...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            isPulsing = true
        }
    }
}
