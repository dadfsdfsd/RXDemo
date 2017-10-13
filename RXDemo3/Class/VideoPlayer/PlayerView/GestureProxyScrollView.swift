//
// Created by fan yang on 2017/10/12.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit

class GestureProxyScrollView: UIScrollView, UIGestureRecognizerDelegate {

    var gesEnabled: Bool?

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        guard gesEnabled != nil || gesEnabled == true else { return false }
        if bounds.contains(point) {
            return true
        }
        return false

    }
}