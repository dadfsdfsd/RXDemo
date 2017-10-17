//
// Created by fan yang on 2017/9/20.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol ViewModel {

    associatedtype Input

    associatedtype Output
    
    func transform(input: Input) -> Output

}

class RxViewController<ViewModel>: UIViewController {
    
    var disposeBag = DisposeBag()
    
    var needBindWhenViewDidLoad: Bool = false
    
    var viewModel: ViewModel? {
        willSet {
            willBind(to: newValue, oldViewModel: self.viewModel)
        }
        
        didSet {
            if isViewLoaded {
                didBind(to: viewModel)
            }
            else {
                needBindWhenViewDidLoad = true
            }
        }
    }
    
    func willBind(to viewModel: ViewModel?, oldViewModel: ViewModel?) {
        disposeBag = DisposeBag()
    }
    
    func didBind(to viewModel: ViewModel?) {
        
    }
    
    func loadViewModel() -> ViewModel? {
        return nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if viewModel == nil {
            viewModel = loadViewModel()
        }
        else if needBindWhenViewDidLoad {
            didBind(to: viewModel)
        }
        needBindWhenViewDidLoad = false
        view.backgroundColor = UIColor.white
    }
}


class BaseViewController<ViewModel>: RxViewController<ViewModel> {




}
