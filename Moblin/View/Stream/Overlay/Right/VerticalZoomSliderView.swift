import SwiftUI

private let knobSize = 28.0

private struct VerticalZoomSliderInnerView: View {
    let model: Model
    @ObservedObject var level: ZoomLevel

    private func range() -> (Float, Float) {
        let (minX, maxX) = model.getMinMaxZoomX(position: model.cameraPosition ?? .back)
        return (max(minX, 0.1), max(min(maxX, 10), max(minX, 0.1) * 1.01))
    }

    private func fraction() -> Double {
        let (minX, maxX) = range()
        let x = min(max(level.x, minX), maxX)
        return Double(log(x / minX) / log(maxX / minX))
    }

    private func setZoom(fraction: Double) {
        let (minX, maxX) = range()
        let fraction = Float(fraction.clamped(to: 0 ... 1))
        model.setZoomX(x: minX * pow(maxX / minX, fraction))
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.magnifyingglass")
            GeometryReader { reader in
                let travel = max(reader.size.height - knobSize, 1)
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.5))
                        .frame(width: 4)
                        .frame(maxHeight: .infinity)
                    Circle()
                        .fill(.white)
                        .frame(width: knobSize, height: knobSize)
                        .shadow(radius: 2)
                        .offset(y: (1 - fraction()) * travel)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            setZoom(fraction: 1 - (value.location.y - knobSize / 2) / travel)
                        }
                )
            }
            Image(systemName: "minus.magnifyingglass")
            Text(String(format: "%.1fx", level.x))
                .font(.caption2)
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
        .frame(width: 44, height: 240)
        .background(Color.black.opacity(0.4))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(pickerBorderColor))
    }
}

struct VerticalZoomSliderView: View {
    let model: Model
    @ObservedObject var zoom: Zoom

    var body: some View {
        if zoom.hasZoom {
            VerticalZoomSliderInnerView(model: model, level: zoom.level)
        }
    }
}
