//
//  Button.swift
//

import SwiftUI

class Button: UIButton {
    var tapAction: (() -> ())! = nil
    required init(color: CGColor) {
        let size = UIScreen.main.bounds.height * 0.05
        let cgRect = CGRect(x: UIScreen.main.bounds.width * 0.8, y: UIScreen.main.bounds.height * 0.9, width: size, height: size)
        super.init(frame: cgRect)
        
        backgroundColor = .clear
        layer.cornerRadius = frame.size.width / 3
        layer.borderWidth = 3
        layer.borderColor = color
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
