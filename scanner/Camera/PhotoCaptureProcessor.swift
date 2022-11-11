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
