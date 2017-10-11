//
//  UIFont+Mp.swift
//  Meipu
//
//  Created by XiaoshaQuan on 9/15/16.
//  Copyright © 2016 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    // 价格字体
    class func mpLightNumberFont(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "AvenirLTStd-Heavy", size: size) {
            return font
        }
        
        return mpFontOfSize(size)
    }
    
    class func mpNumberFont(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "AvenirLTStd-Black", size: size) {
            return font
        }
        
        return mpFontOfSize(size)
    }
}

extension UIFont {
    // icon 字体
    class func mpIconFont(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "iconfont", size: size) {
            return font
        }
        
        return mpFontOfSize(size)
    }
}

extension UIFont {
    
    class func mpLightFontOfSize(_ size: CGFloat) -> UIFont {
        
        var font: UIFont? = nil
        
        if #available(iOS 9.0, *) {
            font = UIFont(name: ".SFUIText-Light", size: size)
        } else {
            font = UIFont(name: ".HelveticaNeueInterface-Light", size: size)
        }
        
        if let font = font {
            return font
        } else {
            assertionFailure()
            return mpFontOfSize(size)
        }
    }
    
    class func mpItalicFontOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.italicSystemFont(ofSize: size)
    }
    
    class func mpFontOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }
    
    class func mpBoldFontOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.boldSystemFont(ofSize: size)
    }
    
    class func mpEmojiFont() -> UIFont {
        
        if UIScreen.main.bounds.size.width == 320.0 {
            
            return UIFont.mpFontOfSize(24)
        } else {
            
            return UIFont.mpFontOfSize(30);
        }
    }
    
    var labelLineHeight: CGFloat {
        let label = UILabel()
        label.text = " "
        label.font = self
        label.sizeToFit()
        return label.height
    }
}
