import AVFoundation
import Combine
import SwiftUI

/// Class responsible for the barcode scanner view flow.
final class OSBARCScannerBehaviour: OSBARCCoordinatable, OSBARCScannerProtocol {
    /// A publisher value responsible for the resulting scanned value.
    @Published private var scanResult: OSBARCScanResult = OSBARCScanResult.empty()
    
    /// The publisher's cancellable instance collector.
    private var cancellables: Set<AnyCancellable> = []
    
    func startScanning(with parameters: OSBARCScanParameters, _ completion: @escaping (OSBARCScanResult) -> Void) {
        // Reset scan result to clear any previous bounding box
        self.scanResult = OSBARCScanResult.empty()

        let closeDelay = parameters.closeDelay
        $scanResult
            .dropFirst()    // drops the first value - the empty string
            .first()        // only publishes the first barcode value found
            .sink { result in
                DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) {
                    self.coordinator.dismiss()
                    completion(result)
                }
            }
            .store(in: &cancellables)
        
        let scanResultBinding = Binding(    // binding object filled by the SwiftUI view
            get: {
                self.scanResult
            },
            set: {
                self.scanResult = $0
            }
        )
        
        let buttonText = parameters.scanButtonText ?? ""   // not having the button enabled is translated into having an empty text.
        let shouldShowButton = !buttonText.isEmpty  // if empty text is passed, the button is not enabled on the scanner view
        
        let barcodeDecoder = OSBARCCaptureOutputDecoder(
            scanResultBinding,
            shouldShowButton,
            andHint: parameters.hint,
            vibrationEnabled: parameters.vibrationEnabled
        )
        let captureSessionManager = OSBARCCaptureSessionManager(
            parameters.cameraDirection,
            parameters.scanOrientation,
            barcodeDecoder
        )
        guard let viewModel: OSBARCScannerViewModel = try? .init(cameraManager: captureSessionManager) else { return completion(OSBARCScanResult.empty()) }
        let highlightColor = Color(hex: parameters.highlightColor) ?? .green
        let scannerView = OSBARCScannerView(
            viewModel: viewModel,
            scanResult: scanResultBinding,
            instructionsText: parameters.scanInstructions,
            buttonText: buttonText,
            shouldShowButton: shouldShowButton,
            deviceType: UIDevice.current.userInterfaceIdiom.deviceTypeModel,
            highlightEnabled: parameters.highlightEnabled,
            highlightColor: highlightColor,
            highlightStrokeWidth: parameters.highlightStrokeWidth
        )
        let hostingController = OSBARCScannerViewHostingController(rootView: scannerView, parameters.scanOrientation)
        hostingController.modalPresentationStyle = .fullScreen
        
        self.coordinator.present(hostingController)
    }
}
