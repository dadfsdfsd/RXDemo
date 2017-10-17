//
//  ViewlayoutTestViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/13.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CustomView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        debug_print("CustomView layoutSubviews")
    }
    
}

class ViewLayoutTestViewModel: ViewModel {
 
    
    struct Input {
    }
    
    struct Output {
    }
    
    func transform(input: ViewLayoutTestViewModel.Input) -> ViewLayoutTestViewModel.Output {
        return Output.init()
    }
}


class ViewlayoutTestViewController: BaseViewController<ViewLayoutTestViewModel> {
    
    var customView: CustomView = CustomView()
    var customSubview: CustomView = CustomView()
    
    override func didBind(to viewModel: ViewLayoutTestViewModel?) {
        super.didBind(to: viewModel)
    }
    
    override func loadViewModel() -> ViewLayoutTestViewModel? {
        return ViewLayoutTestViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(customView)
        customView.frame = CGRect.init(x: 0, y: 100, width: self.view.width, height: 200)
        
        customView.addSubview(customSubview)
 
        var i: CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (timer) in
            i += 0.1
            self.customSubview.frame = CGRect.init(x: 0, y: 0, width: 100, height: i)
         }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
