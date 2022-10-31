//
//  PhotoCaptureProcessor.swift
//

import AVFoundation

class PhotoCaptureProcessor: NSObject {
    var capturedPhoto: AVCapturePhoto! = nil
    var image: CGImage! = nil
    var completionHandler: ((CGImage) -> ())! = nil
    var orientation: AVCaptureVideoOrientation = .portrait
    var cropBounds: CGRect! = nil
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { return }
//        capturedPhoto = photo
        image = photo.cgImageRepresentation()!.cropping(to: cropBounds)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard error == nil else { return }
        completionHandler(image)
    }
}
