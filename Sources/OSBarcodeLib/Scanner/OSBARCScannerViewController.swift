import AVFoundation
import Combine
import SwiftUI
import UIKit

/// Class responsible for displaying the camera stream that performs the scanning.
final class OSBARCScannerViewController: UIViewController {
    /// Object responsible for managing all things camera related.
    private let cameraManager: OSBARCCameraManager

    /// Whether highlight overlay is enabled.
    private let highlightEnabled: Bool
    /// The color for the highlight overlay.
    private let highlightColor: UIColor
    /// The stroke width for the highlight overlay.
    private let highlightStrokeWidth: CGFloat

    /// The shape layer used to draw the barcode highlight.
    private var highlightLayer: CAShapeLayer?

    /// The publisher's cancellable instance collector.
    private var cancellables: Set<AnyCancellable> = []

    /// Constructor method.
    /// - Parameters:
    ///   - cameraManager: Object responsible for managing all things camera related.
    ///   - highlightEnabled: Whether to show highlight overlay around detected barcodes.
    ///   - highlightColor: The color for the highlight overlay.
    ///   - highlightStrokeWidth: The stroke width for the highlight overlay.
    init(
        cameraManager: OSBARCCameraManager,
        highlightEnabled: Bool = false,
        highlightColor: UIColor = .green,
        highlightStrokeWidth: CGFloat = 3.0
    ) {
        self.cameraManager = cameraManager
        self.highlightEnabled = highlightEnabled
        self.highlightColor = highlightColor
        self.highlightStrokeWidth = highlightStrokeWidth

        super.init(nibName: nil, bundle: nil)
    }

    /// Required method. This is not used.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let videoPreview = self.cameraManager.videoPreview {
            videoPreview.frame = view.layer.bounds
            view.layer.addSublayer(videoPreview)

            self.cameraManager.start()
        }

        if highlightEnabled {
            setupHighlightLayer()
            setupBarcodeDetectionObserver()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.cameraManager.stop()
        clearHighlight()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let rotationToPerform: OSBARCCameraRotationChange = .init(value: (Int(size.height), Int(size.width)))
        try? self.cameraManager.apply(change: rotationToPerform)

        // Clear highlight during rotation as coordinates will change
        clearHighlight()
    }
}

// MARK: - Highlight Overlay
private extension OSBARCScannerViewController {
    /// Sets up the shape layer for drawing barcode highlights.
    func setupHighlightLayer() {
        let layer = CAShapeLayer()
        layer.strokeColor = highlightColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = highlightStrokeWidth
        layer.lineCap = .round
        layer.lineJoin = .round
        view.layer.addSublayer(layer)
        highlightLayer = layer
    }

    /// Sets up the observer for barcode detection notifications.
    func setupBarcodeDetectionObserver() {
        NotificationCenter.default
            .publisher(for: .barcodeDetected)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let boundingBox = notification.object as? CGRect else { return }
                self?.showHighlight(for: boundingBox)
            }
            .store(in: &cancellables)
    }

    /// Shows the highlight overlay at the barcode's position.
    /// - Parameter boundingBox: The normalized bounding box from Vision (origin at bottom-left, values 0-1).
    func showHighlight(for boundingBox: CGRect) {
        guard let previewLayer = cameraManager.videoPreview as? AVCaptureVideoPreviewLayer else { return }

        // Vision coordinates: origin at bottom-left, y increases upward
        // Metadata output coordinates: origin at top-left, y increases downward
        // Convert by flipping y: newY = 1 - oldY - height
        let metadataRect = CGRect(
            x: boundingBox.minX,
            y: 1 - boundingBox.maxY,
            width: boundingBox.width,
            height: boundingBox.height
        )

        // Use AVCaptureVideoPreviewLayer's built-in conversion which handles:
        // - Video gravity (aspectFill/aspectFit)
        // - Device orientation
        let convertedRect = previewLayer.layerRectConverted(fromMetadataOutputRect: metadataRect)

        // Create rounded rectangle path
        let path = UIBezierPath(roundedRect: convertedRect, cornerRadius: 8)
        highlightLayer?.path = path.cgPath

        // Ensure highlight layer is on top
        if let highlightLayer = highlightLayer {
            view.layer.addSublayer(highlightLayer)
        }
    }

    /// Clears the highlight overlay.
    func clearHighlight() {
        highlightLayer?.path = nil
    }
}
