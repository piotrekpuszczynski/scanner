//
//  ImagePredictor.swift
//

import CoreML
import Vision

class ImagePredictor {
    static func createVisionModel() -> VNCoreMLModel {
        guard let url = Bundle.main.url(forResource: "KerasMNIST", withExtension: "bin") else {
            fatalError("Failed to load model.")
        }
        guard let modelURL = try? MLModel.compileModel(at: url) else {
            fatalError("Failed to load url.")
        }
        guard let visionModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
            fatalError("Failed to create a `VNCoreMLModel` instance.")
        }
        return visionModel
    }
}
