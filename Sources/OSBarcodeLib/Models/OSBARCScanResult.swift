import CoreGraphics

public struct OSBARCScanResult: Equatable {
    /// The actual textual data that was scanned
    public let text: String

    /// The format that was scanned, or `unknown` if unable to determine
    public let format: OSBARCScannerHint

    /// The bounding box of the detected barcode in normalized coordinates (0-1).
    public let boundingBox: CGRect?

    public init(text: String, format: OSBARCScannerHint, boundingBox: CGRect? = nil) {
        self.text = text
        self.format = format
        self.boundingBox = boundingBox
    }
}

extension OSBARCScanResult {
    static func empty() -> OSBARCScanResult {
        return OSBARCScanResult(text: "", format: .unknown, boundingBox: nil)
    }
}
