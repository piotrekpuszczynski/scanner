//
//  DetectionHandler.swift
//

import Vision

class DetectionHandler {
    var preprocessObservation: (() -> ()) = {}
    var processObservation: ((_: String, _: CGRect) -> ()) = { _, _ in }
    var postprocessObservation: (() -> ()) = {}
    public func handeler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: { [unowned self] in
            if let results = request.results {
                guard let observations = results as? [VNRecognizedTextObservation] else { return }
                extractDetections(observations)
            }
        })
    }

    private func extractDetections(_ observations: [VNRecognizedTextObservation]) {
        preprocessObservation()
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { return }
            
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            guard let boundingBox = boxObservation?.boundingBox else { return }

            processObservation(candidate.string, boundingBox)
        }
        postprocessObservation()
    }
}
