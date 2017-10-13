//
//  MPVPCacheUnit.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/8.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation

enum VideoCacheUnitStrategy {
    case Local
    case Remote
}

class VideoCacheUnit: Equatable, Hashable {

    var strategy: VideoCacheUnitStrategy
    var range: Range<Int>

    init(with strategy: VideoCacheUnitStrategy, range: Range<Int>) {
        self.strategy = strategy
        self.range = range
    }

    static func ==(lsh: VideoCacheUnit, rhs: VideoCacheUnit) -> Bool {
        return (lsh.range == rhs.range) && lsh.strategy==rhs.strategy
    }

    var hashValue: Int {
        return "\((range))\(strategy)".hashValue
    }
}
