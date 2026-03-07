import AVFoundation
import Combine
import SwiftUI
import Vision

/// Class responsible for decoding the scanning output (in this case, barcodes).
final class OSBARCCaptureOutputDecoder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    /// The object containing the value to return.
    @Binding private var scanResult: OSBARCScanResult
    /// Indicates if scanning should be done only  after a button click or automatically.
    private let scanThroughButton: Bool
    /// Indicates if scanning is enabled (when there's a Scan Button).
    private var scanButtonEnabled: Bool
    /// A hint, to scan a specific format (e.g. only qr code). `Nil` or `unknown` value means it can scan all.
    private var hint: OSBARCScannerHint?
    /// Indicates if vibration should occur on successful scan.
    private let vibrationEnabled: Bool
    /// Indicates if center-line-only scanning is enabled.
    private let scanLineEnabled: Bool

    /// The publisher's cancellable instance collector.
    private var cancellables: Set<AnyCancellable> = []

    /// Constructor.
    /// - Parameters:
    ///   - scanResult: Binding object with the value to return.
    ///   - scanThroughButton: Boolean indicating if scanning should be performed automatically or after clicking the Scan Button.
    ///   - scanButtonEnabled: Indicates if scanning has already been set on.
    ///   - hint: The optional hint, to scan a specific format (e.g. only qr code). `Nil` or `unknown` value means it can scan all.
    ///   - vibrationEnabled: Indicates if vibration should occur on successful scan.
    ///   - scanLineEnabled: Indicates if center-line-only scanning is enabled.
    init(_ scanResult: Binding<OSBARCScanResult>, _ scanThroughButton: Bool, _ scanButtonEnabled: Bool = false, andHint hint: OSBARCScannerHint? = nil, vibrationEnabled: Bool = true, scanLineEnabled: Bool = false) {
        self._scanResult = scanResult
        self.scanThroughButton = scanThroughButton
        self.scanButtonEnabled = scanButtonEnabled
        self.hint = hint
        self.vibrationEnabled = vibrationEnabled
        self.scanLineEnabled = scanLineEnabled
        super.init()
        
        NotificationCenter.default
            .publisher(for: .scanFrameChanged)
            .receive(on: RunLoop.main)  // receive this on the main thread
            .sink { // performed this when `scanFrameChanged` gets triggered (on screen rotation).
                if let imageRect = $0.object as? CGRect, let regionOfInterest = self.scanRegionOfInterest(for: imageRect) {
                    self.detectBarcodeRequest.regionOfInterest = regionOfInterest   // update `regionOfInterest`
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: .scanButtonSelection)
            .receive(on: RunLoop.main)  // receive this on the main thread
            .sink { // performed this when `scanButtonSelection` gets triggered.
                if let enabled = $0.object as? Bool {
                    self.scanButtonEnabled = enabled
                }
            }
            .store(in: &cancellables)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Output should only be processed when scanning is automatically or it has been enabled through the Scan Button.
        guard !self.scanThroughButton || self.scanButtonEnabled else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions: [VNImageOption: Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer, orientation: self.deviceExifOrientation(), options: requestOptions
        )
        try? imageRequestHandler.perform([self.detectBarcodeRequest])
    }
    
    /// Vision request to perform. It gets initialised only once and when needed.
    lazy private var detectBarcodeRequest: VNDetectBarcodesRequest = {
        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
            guard error == nil else { return }
            self.processClassification(for: request)
        })
        barcodeRequest.symbologies = (self.hint ?? .unknown).toVNBarcodeSymbologies()
        
        return barcodeRequest
    }()
}

// MARK: - Private methods
private extension OSBARCCaptureOutputDecoder {
    /// Processes the Vision request to return the desired barcode value.
    /// - Parameter request: Vision request handler that performs image analysis.
    func processClassification(for request: VNRequest) {
        DispatchQueue.main.async {
            if let bestResult = request.results?.first as? VNBarcodeObservation, bestResult.confidence > 0.9, let payload = bestResult.payloadStringValue {
                // If scan line mode is enabled, only process barcodes that cross the center line
                // Vision coordinates: origin bottom-left, Y increases upward (0 to 1)
                if self.scanLineEnabled {
                    let roi = self.detectBarcodeRequest.regionOfInterest
                    let roiCenterY = roi.midY
                    let boundingBox = bestResult.boundingBox
                    let crossesCenterLine = boundingBox.minY < roiCenterY && boundingBox.maxY > roiCenterY
                    guard crossesCenterLine else { return }
                }
                if self.vibrationEnabled {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                let format = OSBARCScannerHint.fromVNBarcodeSymbology(bestResult.symbology, withHint: self.hint)
                let boundingBox = bestResult.boundingBox

                // Post notification for highlight overlay (UIKit handles the coordinate conversion)
                NotificationCenter.default.post(name: .barcodeDetected, object: boundingBox)

                self.scanResult = OSBARCScanResult(text: payload, format: format, boundingBox: boundingBox)
            }
        }
    }
    
    /// Projects a rectangle from image coordinates into normalized coordinates.
    /// The normalized coordinates is the format expected by Vision's Region of Interest.
    /// More detail on https://developer.apple.com/documentation/vision/vnimagebasedrequest/2877482-regionofinterest.
    /// - Parameter imageRect: The coordinates to convert
    /// - Returns: The converted coordinates. If can return `nil` if not able to fetch the screens bounds to base on.
    func scanRegionOfInterest(for imageRect: CGRect) -> CGRect? {
        guard let screenBounds = UIApplication.firstKeyWindowForConnectedScenes?.windowScene?.screen.bounds else { return nil }
        return VNNormalizedRectForImageRect(imageRect, Int(screenBounds.width), Int(screenBounds.height))
    }
    
    /// Converts device orientation into the intended image's display orientation.
    /// - Returns: The equivalent `CGImagePropertyOrientation` to use for the device's current orientation.
    func deviceExifOrientation() -> CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .landscapeRight: return .upMirrored
        case .portraitUpsideDown: return .leftMirrored
        case .landscapeLeft: return .downMirrored
        case .portrait: return .rightMirrored
        default:    // unknown or flat.
            var screenBounds: CGRect?
            DispatchQueue.main.sync {   // This needs to be done as `UIApplication` calls need to be done on the main thread.
                screenBounds = UIApplication.firstKeyWindowForConnectedScenes?.windowScene?.screen.bounds
            }
            guard let screenBounds, screenBounds.width > screenBounds.height
            else { return .rightMirrored }  // assume portrait
            return .downMirrored    // assume landscapeLeft
        }
    }
}
