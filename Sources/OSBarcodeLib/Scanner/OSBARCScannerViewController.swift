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

    /// Sets up the observer for barcode highlight frame notifications.
    func setupBarcodeDetectionObserver() {
        // Listen for screen-coordinate frames from AVCaptureMetadataOutput
        // These are already transformed by Apple's transformedMetadataObject API
        NotificationCenter.default
            .publisher(for: .barcodeHighlightFrame)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let screenRect = notification.object as? CGRect else { return }
                self?.showHighlight(at: screenRect)
            }
            .store(in: &cancellables)
    }

    /// Shows the highlight overlay at the given screen coordinates.
    /// - Parameter screenRect: The barcode bounds in screen coordinates (from transformedMetadataObject).
    func showHighlight(at screenRect: CGRect) {
        // Create rounded rectangle path - coordinates are already in screen space
        let path = UIBezierPath(roundedRect: screenRect, cornerRadius: 8)

        // Disable implicit animations for instant updates (no lag)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlightLayer?.path = path.cgPath
        CATransaction.commit()

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
