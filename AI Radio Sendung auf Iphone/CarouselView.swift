import SwiftUI
import UIKit

enum CarouselStyle {
    case portrait
    case landscape
}

struct CarouselView: View {
    let shows: [ShowItem]
    let selectedIndex: Int
    var style: CarouselStyle = .portrait
    let onSelect: (Int) -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = style == .landscape
            let cardWidth = min(
                geometry.size.width * (isLandscape ? 0.62 : 0.82),
                geometry.size.height * (isLandscape ? 0.82 : 0.90),
                isLandscape ? 330 : 342
            )
            let spacing = cardWidth * (isLandscape ? 0.66 : 0.70)
            let sideYOffset: CGFloat = isLandscape ? 10 : 12

            ZStack {
                ForEach(Array(shows.enumerated()), id: \.element.id) { index, show in
                    let relative = relativePosition(for: index)
                    let xOffset = CGFloat(relative) * spacing + dragOffset
                    let progress = xOffset / spacing
                    let distance = abs(progress)
                    let scale = max(CGFloat(0.74), CGFloat(1) - distance * CGFloat(0.18))
                    let opacity = max(CGFloat(0.38), CGFloat(1) - distance * CGFloat(0.30))
                    let saturation = max(CGFloat(0.62), CGFloat(1) - distance * CGFloat(0.22))

                    if distance < 2.25 {
                        CoverCard(show: show)
                            .frame(width: cardWidth, height: cardWidth)
                            .scaleEffect(scale)
                            .opacity(Double(opacity))
                            .blur(radius: distance < CGFloat(0.22) ? 0 : min(distance * CGFloat(3.8), CGFloat(5.8)))
                            .saturation(Double(saturation))
                            .rotation3DEffect(
                                .degrees(Double(-progress) * (isLandscape ? 5 : 7)),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.72
                            )
                            .offset(x: xOffset, y: distance * sideYOffset)
                            .zIndex(10 - Double(distance))
                            .shadow(color: .black.opacity(distance < CGFloat(0.35) ? 0.45 : 0.22), radius: distance < CGFloat(0.35) ? 30 : 14, x: 0, y: 18)
                            .onTapGesture {
                                guard index != selectedIndex else { return }
                                withAnimation(.spring(response: 0.48, dampingFraction: 0.80)) {
                                    onSelect(index)
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let step = dragStep(from: value, spacing: spacing)

                        guard step != 0 else {
                            withAnimation(.spring(response: 0.46, dampingFraction: 0.78, blendDuration: 0.12)) {
                                dragOffset = 0
                            }
                            return
                        }

                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

                        let releaseOffset = value.translation.width
                        dragOffset = releaseOffset + CGFloat(step) * spacing

                        var indexTransaction = Transaction()
                        indexTransaction.disablesAnimations = true
                        withTransaction(indexTransaction) {
                            onSelect(selectedIndex + step)
                        }

                        withAnimation(.spring(response: 0.46, dampingFraction: 0.78, blendDuration: 0.12)) {
                            dragOffset = 0
                        }
                    }
            )
        }
    }

    private func relativePosition(for index: Int) -> Int {
        guard !shows.isEmpty else { return 0 }

        var distance = index - selectedIndex
        let count = shows.count

        if distance > count / 2 {
            distance -= count
        } else if distance < -count / 2 {
            distance += count
        }

        return distance
    }

    private func dragStep(from value: DragGesture.Value, spacing: CGFloat) -> Int {
        let predicted = value.predictedEndTranslation.width
        var step = Int(round(-predicted / spacing))

        if step == 0, abs(value.translation.width) > spacing * 0.22 {
            step = value.translation.width < 0 ? 1 : -1
        }

        return max(-3, min(3, step))
    }
}

private struct CoverCard: View {
    let show: ShowItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            coverImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.12), .black.opacity(0.70)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(show.subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        )
        .compositingGroup()
    }

    @ViewBuilder
    private var coverImage: some View {
        if let image = UIImage(named: show.coverImageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.pink, .orange, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "waveform")
                    .font(.system(size: 70, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
    }
}
