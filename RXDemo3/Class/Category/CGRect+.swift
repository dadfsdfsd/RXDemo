//
//  CGRect+.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/17.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

extension CGRect{
    init(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ height:CGFloat) {
        self.init(x:x,y:y,width:width,height:height)
    }
    
}
extension CGSize{
    init(_ width:CGFloat,_ height:CGFloat) {
        self.init(width:width,height:height)
    }
}
extension CGPoint{
    init(_ x:CGFloat,_ y:CGFloat) {
        self.init(x:x,y:y)
    }
}

extension CGRect {
    func applyInsets(_ insets: UIEdgeInsets) -> CGRect {
        return CGRect(origin.x + insets.left, origin.y + insets.top, width - insets.left - insets.right, height - insets.top - insets.bottom)
    }
}

extension CGRect {
    
    init(center: CGPoint, size: CGSize) {
        self.init(center.x - size.width/2.0 , center.y - size.height/2.0, size.width, size.height)
    }
}

