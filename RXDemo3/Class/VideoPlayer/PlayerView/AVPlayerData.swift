//
// Created by fan yang on 2017/10/12.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

open class AVPlayerData: NSObject {

    var size: CGSize = .zero

    var contextID: Int64 = 0

    var isMute: Bool = true

    var seekTime: CMTime = kCMTimeZero

    var autoPlayWhenNextAppear: Bool = true

    var isPausedByUser: Bool = false

    var canPlayWhenNotWifi: Bool = false;

    var urlString: String = ""

    override init() {
        super.init()
    }

}