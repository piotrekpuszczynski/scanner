//
//  CameraDetector.swift
//

import AVFoundation
import UIKit
import Vision

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            if performRequests {
                try requestHandler.perform(requests)
            }
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
}
