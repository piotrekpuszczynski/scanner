//
//  Button.swift
//

import SwiftUI

class Button: UIButton {
    required init(cgRect: CGRect, color: CGColor, action: Selector) {
        super.init(frame: cgRect)
        
        backgroundColor = .clear
        layer.cornerRadius = frame.size.width / 3
        layer.borderWidth = 3
        layer.borderColor = color
        addTarget(parentFocusEnvironment, action: action, for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
