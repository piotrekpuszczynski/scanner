//
//  ResultsView.swift
//

import SwiftUI
import Vision

class ResultsView: UIImageView {
    private let cgImage: CGImage
    private let interfaceColor: CGColor
    private let detectionLayer = CALayer()

    required init(cgImage: CGImage, screenRect: CGRect, interfaceColor: CGColor) {
        let image = UIImage(cgImage: cgImage)
        self.cgImage = cgImage
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
        let detectionHandler = DetectionHandler()
        detectionHandler.processObservation = { [unowned self] string, boundingBox in
            print(string)

            let rect = VNImageRectForNormalizedRect(boundingBox, Int((image?.size.width)!), Int((image?.size.height)!))
            let boxLayer = drawBoundingBox(rect)
            detectionLayer.addSublayer(boxLayer)
        }
        
        let request = VNRecognizeTextRequest(completionHandler: detectionHandler.handeler)
        request.recognitionLevel = .accurate

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.main.async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error in performing Image request: \(error)")
            }
        }
    }

    private func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 2.0
        boxLayer.borderColor = interfaceColor
//        boxLayer.backgroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.25)
//        boxLayer.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.25)
        boxLayer.cornerRadius = 4
        return boxLayer
    }
}
