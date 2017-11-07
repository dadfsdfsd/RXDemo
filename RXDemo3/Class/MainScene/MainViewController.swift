//
//  ViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/9/20.
//  Copyright © 2017 fan yang. All rights reserved.
//

import UIKit
import IGListKit
import RxCocoa
import RxSwift


class MainViewController: BaseCollectionViewController<MainViewModel> {
    
    lazy var rightBtn: UIBarButtonItem = {
        UIBarButtonItem.init(title: "ADD", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
    }()
    
    override func loadViewModel() -> MainViewModel? {
        return MainViewModel()
    }

    override var viewModelInput: MainViewModel.Input {
        return MainViewModel.Input(addTrigger: rightBtn.rx.tap.asDriver())
    }
    
    override var cellModelToCell: [String : BaseCollectionViewCell.Type] {
        return [MainCellModel.cellIdentifier:  MainCollectionViewCell.self]
    }
    
    override func bind(to output: MainViewModel.Output) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "HOME"
        self.navigationItem.rightBarButtonItem = rightBtn
        
        
    }
    
    
    
    @objc func onTapRight() {
 
    }
    
    override func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, didSelectItemAt index: Int, viewModel: Any) {
        
        guard let _ = viewModel as? MainCellModel else { return }
        
        if index == 0 {
            let vc = PlayerContainerViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if index == 1 {
            self.navigationController?.pushViewController(ViewlayoutTestViewController(), animated: true)
        }
        else if index == 2 {
            self.navigationController?.pushViewController(LoadMoreViewController(), animated: true)
        }
        else if index == 3 {
            self.navigationController?.pushViewController(QYSDK.shared().sessionViewController(), animated: true)
        }
        
    }
 
}
