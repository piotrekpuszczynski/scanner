//
//  CameraDetector.swift
//

//import AVFoundation
//import Vision
//
//extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        if !performRequests { return }
//        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
//            
//            do {
//                try requestHandler.perform(requests)
//            } catch {
//                print("Unable to perform the requests: \(error).")
//            }
//        }
//    }
//}
