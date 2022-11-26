//
//  DetectionHandler.swift
//

import AVFoundation
import Vision

class Detector: NSObject {
    internal func handeler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: { [unowned self] in
            if let results = request.results {
                extractDetections(results: results)
            }
        })
    }

    internal func extractDetections(results: [VNObservation]) {}
}

protocol InformingDelegate {
    func rectChanged() -> CGRect?
}

class FastDetector: Detector, AVCaptureVideoDataOutputSampleBufferDelegate, InformingDelegate {
    public var performRequests = true
    internal var requests: Array<VNRequest>! = nil
    internal let layer: CALayer
    internal let screenRect: CGRect
    internal let color: CGColor
    internal var detectedRect: CGRect?

    init(layer: CALayer, screenRect: CGRect, color: CGColor) {
        self.layer = layer
        self.screenRect = screenRect
        self.color = color
        super.init()
    }

    func rectChanged() -> CGRect? {
        return detectedRect
    }

    internal func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = color
        boxLayer.cornerRadius = 4
        return boxLayer
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

class AccurateDetector: Detector {
    public var text = ""
    
    init(cgImage: CGImage) {
        super.init()

        let request = VNRecognizeTextRequest(completionHandler: handeler)
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.main.async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error in performing Image request: \(error)")
            }
        }
    }

    override func extractDetections(results: [VNObservation]) {
        guard let observations = results as? [VNRecognizedTextObservation] else { return }
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { return }
            text += "\(candidate.string)\n"
        }
    }
}

class FastVision: FastDetector {
    override init(layer: CALayer, screenRect: CGRect, color: CGColor) {
        super.init(layer: layer, screenRect: screenRect, color: color)
        
        let request = VNRecognizeTextRequest(completionHandler: handeler)
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false

        requests = [request]
    }
    
    override func extractDetections(results: [VNObservation]) {
        let rectsArray = RectsArray()
        guard let observations = results as? [VNRecognizedTextObservation] else { return }
        layer.sublayers = nil

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { return }

            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)

            guard let boundingBox = boxObservation?.boundingBox else { return }

            rectsArray.append(boundingBox)
        }

        guard let biggestRect = rectsArray.getBiggest() else { return }

        let objectBounds = VNImageRectForNormalizedRect(biggestRect, Int(screenRect.size.width), Int(screenRect.size.height))
        let textRect = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY,
                              width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
        let increased = textRect.resize(percentage: 1.75)

        detectedRect = increased
        let textBounds = drawBoundingBox(increased)
        layer.addSublayer(textBounds)
    }
}
