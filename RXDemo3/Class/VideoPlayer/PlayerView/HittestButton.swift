//
//  WButton.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/7/5.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import UIKit
import Foundation

class HittestButton: UIButton {

    var hitExpand = UIEdgeInsets()

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitExpand)
        return hitFrame.contains(point)
    }

}
