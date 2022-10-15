//
//  CameraRunner.swift
//

import SwiftUI

struct CameraRunner: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraController {
        return CameraController()
    }
    
    func updateUIViewController(_ uiViewController: CameraController, context: Context) {
        
    }
}
