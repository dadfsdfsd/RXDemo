//
//  Array+.swift
//  RXDemo3
//
//  Created by fan yang on 2017/11/1.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation

extension Array {
    
    func prefix(maxLength: Int) -> [Array.Element] {
        if maxLength <= 0 {
            return []
        }
        else if maxLength < self.count {
            return self
        }
        return Array(self.prefix(upTo: maxLength))
    }
    
}
