import Foundation

extension Notification.Name {
    /// Notification triggered when barcode's scan frame gets changed.
    static let scanFrameChanged = Notification.Name("scanFrameChanged")
    /// Notification triggered when the scan barcode button gets enabled or disabled.
    static let scanButtonSelection = Notification.Name("scanButtonSelection")
    /// Notification triggered when a barcode is detected, carrying the bounding box.
    static let barcodeDetected = Notification.Name("barcodeDetected")
    /// Notification triggered with screen-coordinate barcode frame (from AVCaptureMetadataOutput).
    static let barcodeHighlightFrame = Notification.Name("barcodeHighlightFrame")
}
