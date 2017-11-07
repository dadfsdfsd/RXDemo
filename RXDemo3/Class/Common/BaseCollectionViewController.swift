//
// Created by fan yang on 2017/10/3.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import IGListKit

protocol CollectionViewModelOutput {
    var sectionModels: Driver<[SectionModel]> { get }
}



protocol CollectionViewModel: ViewModel where Output: CollectionViewModelOutput {

    
}



class BaseCollectionViewController<ViewModel>: BaseViewController<ViewModel>, ListAdapterDataSource, ListBindingSectionControllerSelectionDelegate, UIScrollViewDelegate  where ViewModel: CollectionViewModel {

    var collectionView: UICollectionView?
    var sectionModels: [ListDiffable] = []
    
    lazy var adapter: ListAdapter = {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)
        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    var cellModelToCell: [String: BaseCollectionViewCell.Type] {
        fatalError()
    }
    
    func loadCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .automatic
        } else {
        }
        collectionView.backgroundColor = UIColor.white
        
        return collectionView
    }

    func layoutCollectionView() {
        collectionView?.snp.makeConstraints() { (make) in
            make.edges.equalTo(self.view)
        }
    }
    
    final override func didBind(to viewModel: ViewModel?) {
        guard let viewModel = viewModel else { return }
        let output = viewModel.transform(input: viewModelInput)
        output.sectionModels.drive(onNext: {[weak self] (sectionModels) in
            self?.sectionModels = sectionModels
            self?.adapter.performUpdates(animated: true, completion: nil)
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        
        bind(to: output)
    }
    
    func bind(to output: ViewModel.Output) {
        
    }
    
    var viewModelInput: ViewModel.Input {
        fatalError()
    }
    
    override func viewDidLoad() {
        collectionView = loadCollectionView()
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = true
        
        adapter.collectionView = collectionView
        adapter.dataSource = self
        
        view.addSubview(collectionView!)
        layoutCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView?.frame = view.bounds
    }
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return sectionModels
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return AnonymousSectionController(cellModelToCell: self.cellModelToCell, delegate: self)
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didSelectItemAt index: Int, viewModel: Any) {
        
         
        
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}


class BaseCollectionViewCell: UICollectionViewCell, ListBindable {
    
    var disposeBag: DisposeBag = DisposeBag()

    func bindCellModel(_ cellModel: CellModel) {
        
    }
    
    func bindViewModel(_ viewModel: Any) {
        if let cellModel = viewModel as? CellModel {
            bindCellModel(cellModel)
        }
        else {
            assertionFailure()
        }
    }
}


class AnonymousSectionController: ListBindingSectionController<CellModel>, ListBindingSectionControllerDataSource {
    
    var disposeBag: DisposeBag = DisposeBag()
    
    var cellModels: [CellModel] = []
    
    var sectionModel: SectionModel? {
        willSet {
            disposeBag = DisposeBag()
        }
        didSet {
            sectionModel?.cellModels.drive(onNext: { (cellModels) in
                self.cellModels = cellModels
                self.update(animated: false, completion: nil)
            }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        }
    }
    
    var cellModelToCell: [String: BaseCollectionViewCell.Type]
    
    init(cellModelToCell: [String: BaseCollectionViewCell.Type], delegate: ListBindingSectionControllerSelectionDelegate ) {
        self.cellModelToCell = cellModelToCell
        super.init()
        self.dataSource = self
        self.selectionDelegate = delegate
    }
    
    override func didUpdate(to object: Any) {
        if let sectionModel = object as? SectionModel {
            self.sectionModel = sectionModel
        }
        super.didUpdate(to: object)
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        return cellModels
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        if let cellModel = viewModel as? CellModel, let cellClass = cellModelToCell["\(type(of: cellModel).cellIdentifier)"], let cell = collectionContext?.dequeueReusableCell(of: cellClass, for: self, at: index) as? BaseCollectionViewCell {
            return cell
        }
        else {
            fatalError()
        }
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        if let cellModel = viewModel as? CellModel {
            return cellModel.expectedSize(for: collectionContext?.containerSize ?? .zero)
        }
        else {
            fatalError()
        }
    }
}

