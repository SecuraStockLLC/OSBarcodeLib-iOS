import SwiftUI

struct OSBARCHighlightOverlay: View {
    /// The bounding box in screen coordinates (already converted from Vision coordinates)
    let screenRect: CGRect
    let color: Color
    let strokeWidth: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(color, lineWidth: strokeWidth)
            .frame(width: screenRect.width, height: screenRect.height)
            .position(x: screenRect.midX, y: screenRect.midY)
    }
}
