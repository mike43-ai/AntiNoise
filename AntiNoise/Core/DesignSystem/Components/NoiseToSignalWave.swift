import SwiftUI

/// Signature brand graphic: chaotic gray noise on the left resolving into a clean orange
/// signal on the right — the "Anti Noise" metaphor. Procedural (no asset), gently animated,
/// and static when Reduce Motion is on.
struct NoiseToSignalWave: View {
    var height: CGFloat = 120

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                Canvas { ctx, size in draw(ctx, size: size, phase: 0) }
            } else {
                TimelineView(.animation) { timeline in
                    let phase = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in draw(ctx, size: size, phase: phase) }
                }
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    private func draw(_ ctx: GraphicsContext, size: CGSize, phase: Double) {
        let w = size.width, h = size.height, mid = h / 2
        let steps = 170
        var path = Path()

        for i in 0...steps {
            let fx = Double(i) / Double(steps)              // 0...1 across the width
            // Amplitude oscillates on the left then decays to a flat line on the right —
            // "noise resolving into a clean signal". Fully flat past ~55% width.
            let env = fx >= 0.55 ? 0 : pow(1 - fx / 0.55, 2.4)
            let noise = sin(fx * 46 + phase * 6)
                + 0.5 * sin(fx * 88 - phase * 4)
                + 0.3 * sin(fx * 129 + phase * 2)
            let amp = env * noise
            let pt = CGPoint(x: fx * w, y: mid + amp * (h * 0.34))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }

        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Color.textMuted.opacity(0.5), Color.accent]),
            startPoint: CGPoint(x: 0, y: mid),
            endPoint: CGPoint(x: w, y: mid)
        )
        ctx.stroke(path, with: shading,
                   style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
    }
}

#Preview {
    ZStack {
        Color.bgPrimary.ignoresSafeArea()
        NoiseToSignalWave()
            .padding()
    }
}
