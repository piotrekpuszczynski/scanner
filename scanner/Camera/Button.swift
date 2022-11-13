//
//  Button.swift
//

import SwiftUI

class Button: UIButton {
    var tapAction: (() -> ())! = nil
    required init(xByPercentage: CGFloat, yByPercentage: CGFloat) {
        let size = UIScreen.main.bounds.height * 0.05
        let cgRect = CGRect(x: UIScreen.main.bounds.width * xByPercentage, y: UIScreen.main.bounds.height * yByPercentage,
                            width: size, height: size)
        super.init(frame: cgRect)
        
        backgroundColor = .clear
        layer.cornerRadius = frame.size.width / 3
        layer.borderWidth = 1
        layer.borderColor = CGColor(gray: 1, alpha: 1)
        layer.backgroundColor = CGColor(gray: 1, alpha: 0.25)
        addTarget(parentFocusEnvironment, action: #selector(tapHandler), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func tapHandler() {
        guard tapAction != nil else { return }
        tapAction()
    }
}
