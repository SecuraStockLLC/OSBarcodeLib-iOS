import SwiftUI

struct OSBARCHighlightOverlay: View {
    let boundingBox: CGRect
    let color: Color
    let strokeWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            // Vision uses bottom-left origin with normalized coords (0-1)
            // Convert to SwiftUI top-left origin
            let rect = CGRect(
                x: boundingBox.minX * geometry.size.width,
                y: (1 - boundingBox.maxY) * geometry.size.height,
                width: boundingBox.width * geometry.size.width,
                height: boundingBox.height * geometry.size.height
            )

            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: strokeWidth)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }
}
