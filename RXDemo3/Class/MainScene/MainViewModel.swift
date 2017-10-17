//
//  MainViewModel.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/10.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation
import RxSwift
import IGListKit
import RxCocoa

class MainViewModel: CollectionViewModel {
    
    struct Input {
        let addTrigger: Driver<Void>
    }
    
    struct Output: CollectionViewModelOutput {
        let sectionModels: SharedSequence<DriverSharingStrategy, [SectionModel]>
    }
    
    func transform(input: Input) -> Output {
         let cellModels = ["Video", "ViewLayout", "LoadMore"].map { (i) -> MainCellModel in
                let title = Driver<String>.from(["\(i)"])
                return MainCellModel(title: title)
            }
        
        let c =  input.addTrigger.scan(cellModels) { (aggregateValue, _) -> [CellModel] in
            let title = Driver<String>.from(["\(aggregateValue.count)"])
            let cell = MainCellModel(title: title)
            var arr = aggregateValue
            arr.append(cell)
            return arr
        }.startWith(cellModels)

        let oneSection = SectionModel(cellModels: c )
        let o = Driver<[SectionModel]>.just([oneSection])
        return Output(sectionModels: o)
    }
}
