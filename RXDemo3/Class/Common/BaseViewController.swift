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
    }
}


class BaseViewController<ViewModel>: RxViewController<ViewModel>, UIGestureRecognizerDelegate {
    
    var shouldGesturePop: Bool = true
    
    var isTransitioning: Bool {
        if let nav = self.navigationController, let isTransitioning = nav.value(forKey: "_isTransitioning") as? Bool, isTransitioning  {
            return true
        }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        view.backgroundColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupPopGesture()
    }
    
    func setupBackButton() {
        if (navigationController?.viewControllers.count ?? 0) > 1 {
            let backButton = UIBarButtonItem.init(image: UIImage(named: "navi_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(onTapBackButton))
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc func onTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    func setupPopGesture() {
        if let nav = self.navigationController, nav.viewControllers.contains(self) {
            nav.interactivePopGestureRecognizer?.isEnabled = nav.viewControllers.count > 1
            nav.interactivePopGestureRecognizer?.delegate = self
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isTransitioning {
            return false
        }
        if let nav = self.navigationController, nav.viewControllers.count > 1 {
            var currentViewController: BaseViewController?
            if let index = nav.viewControllers.index(of: self), index > 0 {
                currentViewController = self
            }
            else{
                currentViewController = nav.viewControllers.last as? BaseViewController
            }
            return currentViewController?.shouldGesturePop ?? false
        }
        return false
    }
}


