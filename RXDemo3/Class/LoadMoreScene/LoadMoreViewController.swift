//
//  LoadMoreViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/16.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import MJRefresh
import RxSwift
import RxCocoa
import IGListKit

extension Reactive where Base: MJRefreshComponent {
   
    var state: UIBindingObserver<Base, MJRefreshState> {
        return UIBindingObserver(UIElement: self.base) { refrshComponent, state in
            refrshComponent.state = state
        }
    }
}



class LoadMoreViewController: BaseCollectionViewController<LoadMoreViewModel> {
    
    let loadMoreTrigger: PublishSubject<Void> = PublishSubject<Void>()
    
    override func loadViewModel() -> LoadMoreViewModel? {
        return LoadMoreViewModel()
    }
    
    override func loadCollectionView() -> UICollectionView {
        let collectionView = super.loadCollectionView()
        let footer = RefreshAutoFooter.init(refreshingBlock: { [weak self] in
            self?.loadMoreTrigger.on(Event.next(()))
        })
        footer?.triggerAutomaticallyRefreshPercent = -10
        collectionView.mj_footer = footer
        return collectionView
    }
    
    override func bind(to output: LoadMoreViewModel.Output) {
        output.footerState.drive(collectionView!.mj_footer.rx.state).disposed(by: disposeBag)
    }
    
    override var viewModelInput: LoadMoreViewModel.Input {
        return LoadMoreViewModel.Input(startNumbers: [Int](0..<5) , loadMoreTrigger: loadMoreTrigger.asDriver(onErrorJustReturn: ()))
    }
    
    override var cellModelToCell: [String : BaseCollectionViewCell.Type] {
        return [LoadMoreCellModel.cellIdentifier:  LoadMoreCollectionViewCell.self]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        debug_print("scrollViewDidScroll")
    }

}


