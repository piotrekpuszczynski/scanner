//
//  Extensions.swift
//

import AVFoundation
import UIKit

extension UIImage {
    var orientationCorrectedImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func cropping(to previewLayer: AVCaptureVideoPreviewLayer, toSizeOf rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let outputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: rect)

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let cropRect = CGRect(x: (outputRect.origin.x * width), y: (outputRect.origin.y * height), width: (outputRect.size.width * width), height: (outputRect.size.height * height))

        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: self.imageOrientation)
        }

        return nil
    }
}

extension CGRect {
    func increase(byPercentage percentage: CGFloat) -> CGRect {
        let adjustmentWidth = (width * percentage) / 2.0
        let adjustmentHeight = (height * percentage) / 2.0
        return CGRectInset(self, -adjustmentWidth, -adjustmentHeight)
    }
}
