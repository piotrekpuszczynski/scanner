//
//  ResultsView.swift
//

import SwiftUI

class ResultsView: UIImageView {
    required init(cgImage: CGImage, rect: CGRect, interfaceColor: CGColor) {
        let image = UIImage(cgImage: cgImage)
        super.init(image: image)
        
        layer.frame = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
//        imageView.center = imageView.convert(imageView.center, from: view);
        center = CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
        backgroundColor = UIColor.clear
//        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
