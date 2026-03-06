import AVFoundation
import SwiftUI

/// Structure responsible for bridging `OSBARCScannerViewController` into SwiftUI.
struct OSBARCScannerViewControllerRepresentable: UIViewControllerRepresentable {
    /// Object responsible for managing all things camera related.
    private let cameraManager: OSBARCCameraManager
    /// Whether highlight overlay is enabled.
    private let highlightEnabled: Bool
    /// The color for the highlight overlay.
    private let highlightColor: UIColor
    /// The stroke width for the highlight overlay.
    private let highlightStrokeWidth: CGFloat

    /// Constructor Method.
    /// - Parameters:
    ///   - cameraManager: Object responsible for managing all things camera related.
    ///   - highlightEnabled: Whether to show highlight overlay around detected barcodes.
    ///   - highlightColor: The color for the highlight overlay.
    ///   - highlightStrokeWidth: The stroke width for the highlight overlay.
    init(
        _ cameraManager: OSBARCCameraManager,
        highlightEnabled: Bool = false,
        highlightColor: UIColor = .green,
        highlightStrokeWidth: CGFloat = 3.0
    ) {
        self.cameraManager = cameraManager
        self.highlightEnabled = highlightEnabled
        self.highlightColor = highlightColor
        self.highlightStrokeWidth = highlightStrokeWidth
    }

    func makeUIViewController(context: Context) -> OSBARCScannerViewController {
        .init(
            cameraManager: cameraManager,
            highlightEnabled: highlightEnabled,
            highlightColor: highlightColor,
            highlightStrokeWidth: highlightStrokeWidth
        )
    }

    func updateUIViewController(_ uiViewController: OSBARCScannerViewController, context: Context) {
        // Required but nothing to do here.
    }
}
