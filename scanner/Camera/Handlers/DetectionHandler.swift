//
//  DetectionHandler.swift
//

import Vision

class DetectionHandler {
    var extractDetections: ((_: [VNRecognizedTextObservation]) -> ()) = { _ in }
    public func handeler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: { [unowned self] in
            if let results = request.results {
                guard let observations = results as? [VNRecognizedTextObservation] else { return }
                extractDetections(observations)
            }
        })
    }
}
