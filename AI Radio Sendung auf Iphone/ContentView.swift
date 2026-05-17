import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayerViewModel()

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                RadioBackground()

                if isLandscape {
                    LandscapePlayerLayout(player: player, geometry: geometry)
                } else {
                    PortraitPlayerLayout(player: player, geometry: geometry)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.container, edges: .all)
        .preferredColorScheme(.dark)
    }
}

private struct PortraitPlayerLayout: View {
    @ObservedObject var player: AudioPlayerViewModel
    let geometry: GeometryProxy

    var body: some View {
        let safe = geometry.safeAreaInsets
        let screenHeight = geometry.size.height
        let usableHeight = screenHeight - safe.top - safe.bottom
        let isVeryCompact = screenHeight < 700
        let isCompact = screenHeight < 820
        let carouselRatio: CGFloat = isVeryCompact ? 0.37 : (isCompact ? 0.42 : 0.47)
        let carouselMin: CGFloat = isVeryCompact ? 220 : (isCompact ? 280 : 330)
        let carouselMax: CGFloat = isVeryCompact ? 260 : (isCompact ? 330 : 390)
        let carouselHeight = min(max(usableHeight * carouselRatio, carouselMin), carouselMax)
        let topPadding = max(safe.top + (isCompact ? 24 : 28), 82)

        VStack(spacing: isCompact ? 10 : 14) {
            HeaderView(showCount: player.shows.count, compact: isCompact)

            CarouselView(
                shows: player.shows,
                selectedIndex: player.selectedIndex,
                style: .portrait,
                onSelect: { index in
                    player.selectShow(index)
                }
            )
            .frame(height: carouselHeight)

            NowPlayingView(player: player, density: isCompact ? .compact : .regular)

            Spacer(minLength: isCompact ? 4 : 10)

            PlayerControlsView(player: player, density: isCompact ? .compact : .regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, isCompact ? 14 : 18)
        .padding(.top, topPadding)
        .padding(.bottom, safe.bottom + 10)
    }
}

private struct LandscapePlayerLayout: View {
    @ObservedObject var player: AudioPlayerViewModel
    let geometry: GeometryProxy

    var body: some View {
        let safe = geometry.safeAreaInsets
        let horizontalPadding: CGFloat = 18
        let verticalPadding: CGFloat = 10
        let trailingPadding = max(horizontalPadding, safe.trailing * 0.45 + 8)
        let topPadding = max(safe.top + 24, 30)
        let contentHeight = geometry.size.height - topPadding - safe.bottom - verticalPadding

        HStack(spacing: 18) {
            CarouselView(
                shows: player.shows,
                selectedIndex: player.selectedIndex,
                style: .landscape,
                onSelect: { index in
                    player.selectShow(index)
                }
            )
            .frame(width: geometry.size.width * 0.52, height: contentHeight)

            VStack(spacing: 12) {
                HeaderView(showCount: player.shows.count, compact: true)

                NowPlayingView(player: player, density: .landscape)

                PlayerControlsView(player: player, density: .landscape)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: contentHeight, alignment: .top)
        }
        .padding(.leading, safe.leading + horizontalPadding)
        .padding(.trailing, trailingPadding)
        .padding(.top, topPadding)
        .padding(.bottom, safe.bottom + verticalPadding)
    }
}

private struct HeaderView: View {
    let showCount: Int
    var compact = false

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("AI Radio")
                    .font(.system(size: compact ? 28 : 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("\(showCount) lokale Shows")
                    .font(.system(size: compact ? 12 : 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: compact ? 23 : 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .orange, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .pink.opacity(0.55), radius: 16, x: 0, y: 0)
        }
    }
}

private struct RadioBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.033, blue: 0.045)

            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.14, blue: 0.42).opacity(0.42),
                    Color(red: 0.95, green: 0.62, blue: 0.14).opacity(0.24),
                    Color(red: 0.04, green: 0.65, blue: 0.70).opacity(0.34),
                    Color(red: 0.035, green: 0.033, blue: 0.045).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AngularGradient(
                colors: [
                    .pink.opacity(0.20),
                    .orange.opacity(0.14),
                    .cyan.opacity(0.18),
                    .green.opacity(0.10),
                    .pink.opacity(0.20)
                ],
                center: .center
            )
            .opacity(0.55)
            .blur(radius: 34)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
