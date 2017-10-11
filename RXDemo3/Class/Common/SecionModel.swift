//
// Created by fan yang on 2017/10/3.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit
import IGListKit
import RxCocoa


class SectionModel: NSObject {
    
    var cellModels: Driver<[CellModel]>
    
    init(cellModels: Driver<[CellModel]>) {
        self.cellModels = cellModels
        super.init()
    }
    
    class var sectionIdentifier:String {
        return "\(self)"
    }
    
    var inset: UIEdgeInsets = .zero
    
}

extension SectionModel: ListDiffable {
    
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
