//
//  ResultsView.swift
//

import SwiftUI
import Vision

class ResultsView: UIImageView {
    private let interfaceColor: CGColor
    private let detectionLayer = CALayer()

    required init(cgImage: CGImage, screenRect: CGRect, interfaceColor: CGColor) {
        let image = UIImage(cgImage: cgImage)
        self.interfaceColor = interfaceColor
        super.init(image: image)
        layer.frame = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        backgroundColor = UIColor.clear
        layer.addSublayer(detectionLayer)

        detectText()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func detectText() {
        guard let cgImage = image?.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: detectionHandler)

        DispatchQueue.main.async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error in performing Image request: \(error)")
            }
        }
    }

    private func detectionHandler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: { [unowned self] in
            if let results = request.results {
                guard let observations = results as? [VNRecognizedTextObservation] else { return }
                extractDetections(observations)
            }
        })
    }

    private func extractDetections(_ observations: [VNRecognizedTextObservation]) {
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { return }
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            guard let boundingBox = boxObservation?.boundingBox else { return }
            
            // Convert the rectangle from normalized coordinates to image coordinates.
            let rect =  VNImageRectForNormalizedRect(boundingBox,
                                                     Int((image?.size.width)!),
                                                     Int((image?.size.height)!))
            print(candidate.string)
            let boxLayer = drawBoundingBox(rect)
            detectionLayer.addSublayer(boxLayer)
        }
    }
    
    private func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = interfaceColor
        boxLayer.cornerRadius = 4
        return boxLayer
    }
}
