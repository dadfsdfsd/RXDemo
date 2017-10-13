//
// Created by fan yang on 2017/10/12.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit

let kScreenWidth = UIScreen.main.bounds.size.width

let kScreenHeight = UIScreen.main.bounds.size.height

let leftFullscreenOfMute: CGFloat = 10.0


func dispatch_main_async_safe(block: @escaping () -> ()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}