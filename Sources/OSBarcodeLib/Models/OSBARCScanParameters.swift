import CoreGraphics

public struct OSBARCScanParameters {
    /// Text to be displayed on the scanner view.
    public let scanInstructions: String

    /// Text to be displayed for the scan button, if this is configured. `Nil` value means that the button will not be shown.
    public let scanButtonText: String?

    // Camera to use for input gathering.
    public let cameraDirection: OSBARCCameraModel

    // Scanner view's orientation.
    public let scanOrientation: OSBARCOrientationModel

    // The optional hint, to scan a specific format (e.g. only qr code). `Nil` or `unknown` value means it can scan all.
    public let hint: OSBARCScannerHint?

    /// Whether to show a highlight overlay around detected barcodes.
    public let highlightEnabled: Bool

    /// The color of the highlight overlay in hex format (e.g., "#00FF00").
    public let highlightColor: String

    /// The stroke width of the highlight overlay.
    public let highlightStrokeWidth: CGFloat

    /// Delay in seconds before dismissing the scanner after a successful scan.
    public let closeDelay: TimeInterval

    /// Whether to vibrate on successful scan.
    public let vibrationEnabled: Bool

    /// Whether to enable center-line-only scanning (red line mode).
    public let scanLineEnabled: Bool

    public init(scanInstructions: String,
                scanButtonText: String?,
                cameraDirection: OSBARCCameraModel,
                scanOrientation: OSBARCOrientationModel,
                hint: OSBARCScannerHint?,
                highlightEnabled: Bool = true,
                highlightColor: String = "#00FF00",
                highlightStrokeWidth: CGFloat = 4.0,
                closeDelay: TimeInterval = 0.5,
                vibrationEnabled: Bool = true,
                scanLineEnabled: Bool = false) {
        self.scanInstructions = scanInstructions
        self.scanButtonText = scanButtonText
        self.cameraDirection = cameraDirection
        self.scanOrientation = scanOrientation
        self.hint = hint
        self.highlightEnabled = highlightEnabled
        self.highlightColor = highlightColor
        self.highlightStrokeWidth = highlightStrokeWidth
        self.closeDelay = closeDelay
        self.vibrationEnabled = vibrationEnabled
        self.scanLineEnabled = scanLineEnabled
    }
}
