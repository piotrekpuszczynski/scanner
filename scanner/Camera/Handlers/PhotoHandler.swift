//
//  PhotoHandler.swift
//

import Vision

class PhotoHandler: DetectionHandler {
    override internal func processObservation(string: String, boundingBox: CGRect) {
        print(candidate.string)
    }
}
