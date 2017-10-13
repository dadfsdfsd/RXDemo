//
// Created by fan yang on 2017/10/12.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit


class SimpleLoadingView: UIView {

    private var animatingView = UIView()

    func startAnimating() {
        isHidden = false
        guard let superview = superview else { return }
        center = CGPoint(x: superview.bounds.size.width/2, y: superview.bounds.size.height/2)
        if animatingView.layer.animation(forKey: "rotationAnimation") == nil {
            addAnimation()
        }
    }

    func stopAnimating() {
        animatingView.layer.removeAllAnimations()
        isHidden = true
    }

    fileprivate func addAnimation() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = 1
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = 10000
        animatingView.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let image = UIImage(named: "icon_video_loading")
        let imgView = UIImageView(image: image)
        addSubview(imgView)

        backgroundColor = UIColor.clear
        animatingView = imgView
        addAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        animatingView.frame = bounds
    }
}