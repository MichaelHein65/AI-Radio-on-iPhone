import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var player: AudioPlayerViewModel
    var density: PlayerPanelDensity = .regular

    var body: some View {
        let skipSize: CGFloat = density == .regular ? 52 : 44
        let sideSize: CGFloat = density == .regular ? 58 : 50
        let playSize: CGFloat = density == .regular ? 82 : 70
        let spacing: CGFloat = density == .regular ? 12 : 9

        HStack(spacing: spacing) {
            ControlButton(
                systemName: "gobackward.15",
                size: skipSize,
                colors: [.cyan, .blue],
                accessibilityLabel: "15 Sekunden zurueck"
            ) {
                player.skip(seconds: -15)
            }

            ControlButton(
                systemName: "backward.end.fill",
                size: sideSize,
                colors: [.purple, .pink],
                accessibilityLabel: "Vorheriger Track"
            ) {
                player.selectPreviousTrack()
            }

            ControlButton(
                systemName: player.isPlaying ? "pause.fill" : "play.fill",
                size: playSize,
                colors: [.orange, .pink, .cyan],
                accessibilityLabel: player.isPlaying ? "Pause" : "Play",
                symbolOffset: player.isPlaying ? 0 : 3
            ) {
                player.togglePlayPause()
            }

            ControlButton(
                systemName: "forward.end.fill",
                size: sideSize,
                colors: [.pink, .orange],
                accessibilityLabel: "Naechster Track"
            ) {
                player.selectNextTrack()
            }

            ControlButton(
                systemName: "goforward.30",
                size: skipSize,
                colors: [.green, .cyan],
                accessibilityLabel: "30 Sekunden vor"
            ) {
                player.skip(seconds: 30)
            }
        }
    }
}

private struct ControlButton: View {
    let systemName: String
    let size: CGFloat
    let colors: [Color]
    let accessibilityLabel: String
    var symbolOffset: CGFloat = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.34, weight: .black))
                .foregroundStyle(.white)
                .offset(x: symbolOffset)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.86)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.26), lineWidth: 1)
                )
                .shadow(color: colors.first?.opacity(0.55) ?? .pink.opacity(0.50), radius: size * 0.22, x: 0, y: size * 0.10)
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
