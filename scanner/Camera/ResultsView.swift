//
//  ResultsView.swift
//

import SwiftUI
import Vision

class ResultsView: UIView {
    private let imageView: UIImageView
    private let cgImage: CGImage
    private let detectionLayer = CALayer()

    required init(cgImage: CGImage, screenRect: CGRect) {
        let image = UIImage(cgImage: cgImage)
        let reducedImage = image.scaleImage(byPercentage: 0.6)
        self.imageView = UIImageView(image: reducedImage)
        self.cgImage = cgImage
        super.init(frame: screenRect)
        layer.frame = screenRect
        
        imageView.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        addSubview(imageView)
        layer.addSublayer(detectionLayer)

        detectText()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func detectText() {
        let detector = AccurateDetector(cgImage: cgImage)
        
        let button = Button(xByPercentage: 0.1, yByPercentage: 0.9)
        button.tapAction = {
            UIPasteboard.general.string = detector.text
            let alert = UIAlertController(title: "Text copied", message: nil, preferredStyle: .alert)
            
            guard let rootViewController = self.window?.rootViewController else { return }
            rootViewController.present(alert, animated: true, completion: {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
                    rootViewController.dismiss(animated: true, completion: nil)
                })
            })
        }
        DispatchQueue.main.async { [unowned self] in
            addSubview(button)
        }
    }
}
