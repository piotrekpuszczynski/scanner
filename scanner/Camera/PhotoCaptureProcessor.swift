//
//  PhotoCaptureProcessor.swift
//

import AVFoundation
import UIKit

class PhotoCaptureProcessor: NSObject {
    var capturedPhoto: AVCapturePhoto! = nil
    var uiImage: UIImage! = nil
    var completionHandler: ((UIImage) -> ())! = nil
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { return }
        if let imageData = photo.fileDataRepresentation() {
            guard let image = UIImage(data: imageData) else { return }
            uiImage = image
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard error == nil && uiImage != nil else { return }
        completionHandler(uiImage)
    }
}

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
