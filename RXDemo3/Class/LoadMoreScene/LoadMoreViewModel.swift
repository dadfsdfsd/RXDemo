//
//  LoadMoreViewModel.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/16.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MJRefresh

class LoadMoreViewModel: CollectionViewModel {

    struct Input {
        let startNumbers:    [Int]
        let loadMoreTrigger: Driver<Void>
    }
    
    struct Output: CollectionViewModelOutput {
        let sectionModels: SharedSequence<DriverSharingStrategy, [SectionModel]>
        let footerState: Driver<MJRefreshState>
    }
    
    func transform(input: LoadMoreViewModel.Input) -> LoadMoreViewModel.Output {
        
        let footerState = PublishSubject<MJRefreshState>()
        
        let startCellModels = input.startNumbers.map { (index) -> CellModel in
            let title = Driver<String>.from(["\(index)"])
            let cell = LoadMoreCellModel(title: title)
            return cell
        }
        
        let cellModels = input.loadMoreTrigger.flatMapLatest { (_)  -> Driver<[Int]> in
            return Observable<[Int]>.of([Int](0...9)).delay(3, scheduler: MainScheduler.instance).asDriver(onErrorJustReturn: [])
            }.do(onNext: { (_) in
                footerState.on(.next(.idle))
            })
            .scan(startCellModels) { (aggregateValue, numbers) -> [CellModel] in
                return aggregateValue + numbers.map({ (index) -> CellModel in
                    let newIndex = aggregateValue.count + index
                    let title = Driver<String>.from(["\(newIndex)"])
                    let cell = LoadMoreCellModel(title: title)
                    return cell
                })
            }.startWith(startCellModels)
        
        let sectionModel = SectionModel.init(cellModels: cellModels)
        let sectionModels = Driver<[SectionModel]>.just([sectionModel])
        return Output.init(sectionModels: sectionModels, footerState: footerState.asDriver(onErrorJustReturn: .idle))
        
    }
}
