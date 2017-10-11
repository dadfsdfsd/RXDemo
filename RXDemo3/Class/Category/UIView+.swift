//
//  UIView+.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/11.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

extension UIView {

    func viewController() -> UIViewController? {
        var target:UIResponder? = self.next
        while target != nil{
            if target!.isKind(of: UIViewController.self){
                break
            }
            target = target?.next
        }
        return target as? UIViewController
    }
}
