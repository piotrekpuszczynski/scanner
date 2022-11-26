//
//  DetectionHandler.swift
//

import AVFoundation
import Vision

class Detector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public var performRequests = true
    internal var requests: Array<VNRequest>! = nil
    var extractDetections: ((_: [VNRecognizedTextObservation]) -> ()) = { _ in }

    override init() {
        super.init()
    }

    public func handeler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: { [unowned self] in
            if let results = request.results {
                guard let observations = results as? [VNRecognizedTextObservation] else { return }
                extractDetections(observations)
            }
        })
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !performRequests { return }
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            do {
                try requestHandler.perform(requests)
            } catch {
                print("Unable to perform the requests: \(error).")
            }
        }
    }
}
