//
//  debug_debug_print.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/12.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

func debug_print<T>(_ message: T, file: String = #file, method: StaticString = #function, line: UInt = #line) {
    #if DEBUG
        print("\(file.lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}


func debug_warning<T>(_ message: T, file: String = #file, method: StaticString = #function, line: UInt = #line) {
    #if DEBUG
        print("!!!WARNING!!!--\(file.lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}

