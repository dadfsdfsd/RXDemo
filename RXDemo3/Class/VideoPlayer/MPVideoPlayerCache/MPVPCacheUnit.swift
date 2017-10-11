//
//  MPVPCacheUnit.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/8.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation

enum MPVPCacheUnitStrategy {
    case Local
    case Remote
}

class MPVPCacheUnit: Equatable, Hashable {

    var strategy: MPVPCacheUnitStrategy
    var range: Range<Int>

    init(with strategy: MPVPCacheUnitStrategy, range: Range<Int>) {
        self.strategy = strategy
        self.range = range
    }

    static func ==(lsh: MPVPCacheUnit, rhs: MPVPCacheUnit) -> Bool {
        return (lsh.range == rhs.range) && lsh.strategy==rhs.strategy
    }

    var hashValue: Int {
        return "\((range))\(strategy)".hashValue
    }
}
