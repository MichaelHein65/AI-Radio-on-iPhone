import Combine
import SwiftUI

enum PlayerPanelDensity {
    case compact
    case regular
    case landscape
}

struct NowPlayingView: View {
    @ObservedObject var player: AudioPlayerViewModel
    var density: PlayerPanelDensity = .regular
    @State private var isScrubbing = false
    @State private var scrubValue: TimeInterval = 0

    private var shownTime: TimeInterval {
        isScrubbing ? scrubValue : player.currentTime
    }

    var body: some View {
        let titleSize: CGFloat = density == .regular ? 26 : 21
        let subtitleSize: CGFloat = density == .regular ? 14 : 12
        let verticalPadding: CGFloat = density == .regular ? 18 : 12
        let horizontalPadding: CGFloat = density == .regular ? 18 : 14
        let panelSpacing: CGFloat = density == .regular ? 14 : 10

        VStack(spacing: panelSpacing) {
            VStack(spacing: 6) {
                Text(player.selectedShow.title)
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.72)

                Text(player.trackTitle.isEmpty ? player.selectedShow.subtitle : player.trackTitle)
                    .font(.system(size: subtitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            ScrubbableProgressBar(
                value: shownTime,
                duration: player.duration,
                onChanged: { newValue in
                    isScrubbing = true
                    scrubValue = newValue
                },
                onEnded: { newValue in
                    player.seek(to: newValue)
                    scrubValue = newValue
                    isScrubbing = false
                }
            )

            HStack {
                Text(AudioPlayerViewModel.formattedTime(shownTime))
                Spacer()
                Text(AudioPlayerViewModel.formattedTime(player.duration))
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.58))

            if let statusMessage = player.statusMessage {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.95))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.84))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 14)
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            if player.isPlaying {
                player.updateProgress()
            }
        }
    }
}

private struct ScrubbableProgressBar: View {
    let value: TimeInterval
    let duration: TimeInterval
    let onChanged: (TimeInterval) -> Void
    let onEnded: (TimeInterval) -> Void

    private var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(max(0, min(value / duration, 1)))
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let knobSize: CGFloat = 20
            let filledWidth = max(knobSize / 2, width * progress)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.14))
                    .frame(height: 10)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .orange, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: filledWidth, height: 10)
                    .shadow(color: .pink.opacity(0.55), radius: 10, x: 0, y: 0)

                Circle()
                    .fill(.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .cyan.opacity(0.65), radius: 10, x: 0, y: 0)
                    .offset(x: min(max(width * progress - knobSize / 2, 0), width - knobSize))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onChanged(time(for: value.location.x, width: width))
                    }
                    .onEnded { value in
                        onEnded(time(for: value.location.x, width: width))
                    }
            )
        }
        .frame(height: 30)
        .accessibilityLabel("Fortschritt")
        .accessibilityValue(AudioPlayerViewModel.formattedTime(value))
    }

    private func time(for xPosition: CGFloat, width: CGFloat) -> TimeInterval {
        guard duration > 0, width > 0 else { return 0 }
        let ratio = max(0, min(xPosition / width, 1))
        return duration * TimeInterval(ratio)
    }
}
