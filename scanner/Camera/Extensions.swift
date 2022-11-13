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

    func scaleImage(byPercentage p: CGFloat) -> UIImage {
        let scaledImageSize = CGSize(width: size.width * p, height: size.height * p)

        let renderer = UIGraphicsImageRenderer(size: scaledImageSize)

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }

        return scaledImage
    }
}

extension CGRect {
    func resize(percentage p: CGFloat) -> CGRect {
        let newW = width * p
        let newH = height * p
        let newX = minX + (width - newW) / 2
        let newY = minY + (height - newH) / 2

        return CGRect(x: newX, y: newY, width: newW, height: newH)
    }

    func merge(_ rect: CGRect) -> CGRect {
        let x = min(minX, rect.minX)
        let y = min(minY, rect.minY)
        let width = rect.minX + rect.width - minX
        let height = max(minY + height, rect.minY + rect.height) - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func area() -> CGFloat {
        return height * width
    }
}
