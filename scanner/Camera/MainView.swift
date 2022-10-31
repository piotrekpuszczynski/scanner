//
//  MainView.swift
//

import SwiftUI

class MainView: UIView {
    init() {
        super.init(frame: UIScreen.main.bounds);
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    
    private func setupView() {
        let controller:CameraController = self.storyboard!.instantiateViewControllerWithIdentifier("MyView") as! CameraController
        controller.view.frame = self.bounds
        self.addSubview(controller.view)
        self.addChildViewController(controller)
        controller.didMoveToParentViewController(self)
    }
}
