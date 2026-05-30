import SwiftUI

/// A one-shot confetti burst that plays when it appears. Drop it into a ZStack overlay
/// on completion/celebration screens. Self-contained — no timers, no external deps.
/// Honours Reduce Motion by rendering nothing.
struct ConfettiView: View {
    var pieceCount: Int = 60
    var duration: Double = 2.2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []
    @State private var launched = false

    private static let palette: [Color] = [.accent, .success, .danger, .textPrimary]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 1.6)
                        .rotationEffect(.degrees(launched ? piece.spin : 0))
                        .offset(
                            x: piece.startX * geo.size.width + (launched ? piece.driftX : 0),
                            y: launched ? geo.size.height + 60 : -40
                        )
                        .opacity(launched ? 0 : 1)
                        .animation(
                            .easeIn(duration: duration * piece.speed).delay(piece.delay),
                            value: launched
                        )
                }
            }
            .onAppear {
                guard !reduceMotion, pieces.isEmpty else { return }
                pieces = (0..<pieceCount).map { _ in Piece.random(palette: Self.palette) }
                // Defer one runloop so the initial (top) state renders before the fall animates.
                DispatchQueue.main.async { launched = true }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private struct Piece: Identifiable {
        let id = UUID()
        let startX: CGFloat      // 0...1 fraction of width
        let driftX: CGFloat      // horizontal drift during fall
        let size: CGFloat
        let color: Color
        let spin: Double
        let delay: Double
        let speed: Double        // multiplier on base duration

        static func random(palette: [Color]) -> Piece {
            Piece(
                startX: .random(in: 0.05...0.95),
                driftX: .random(in: -50...50),
                size: .random(in: 6...11),
                color: palette.randomElement() ?? .accent,
                spin: .random(in: 180...720),
                delay: .random(in: 0...0.35),
                speed: .random(in: 0.8...1.25)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.bgPrimary.ignoresSafeArea()
        Text("🎉").font(.system(size: 80))
        ConfettiView()
    }
}
