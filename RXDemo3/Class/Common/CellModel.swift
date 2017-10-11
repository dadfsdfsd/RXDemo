//
// Created by fan yang on 2017/10/3.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit
import IGListKit

class CellModel: NSObject {
    
    var cachedSize: CGSize?

    func expectedSize(for containerSize: CGSize) -> CGSize {
        if let cachedSize = cachedSize {
            return cachedSize
        }
        cachedSize = calculateSize(for: containerSize)
        return cachedSize!
    }
    
    func calculateSize(for containerSize: CGSize) -> CGSize {
        return CGSize(width: containerSize.width, height: 44)
    }
    
    class var cellIdentifier:String {
        return "\(self)"
    }
}

extension CellModel: ListDiffable {
    
    public func diffIdentifier() -> NSObjectProtocol {
        return "\(self)" as NSString
    }
    
    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        if let object = object as? NSObject {
            return self == object
        }
        return false
    }
    
}

