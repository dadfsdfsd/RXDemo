//
//  PlayerContainerViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/11/6.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift


class PlayerContainerViewModel: ViewModel {
    
    struct Input {
        let playerData: Driver<AVPlayerData>
    }
    
    struct Output {
        let playerData: Driver<AVPlayerData>
    }
    
    func transform(input: PlayerContainerViewModel.Input) -> PlayerContainerViewModel.Output {
        return Output.init(playerData: input.playerData)
    }
}

class PlayerControlProperty<Value> {
    
    private var valueChangeBlocks: [(Value, Value) -> Void] = []
    
    var value: Value {
        didSet {
            for block in valueChangeBlocks {
                block(value, oldValue)
            }
        }
    }
    
    func sendUpdateAction() {
        for block in valueChangeBlocks {
            block(value, value)
        }
    }
    
    init(_ value: Value) {
        self.value = value
    }
    
    func registerValueChange(_ block: @escaping (_ newValue: Value, _ oldValue: Value) -> Void) {
        valueChangeBlocks.append(block)
    }
    
    func clear() {
        valueChangeBlocks = []
    }
}


class PlayerContainerViewController: BaseViewController<PlayerContainerViewModel> {
    
    var playerView: CommonPlayerView = CommonPlayerView()
    
    override func didBind(to viewModel: PlayerContainerViewModel?) {
        super.didBind(to: viewModel)
        
        let playerData = AVPlayerData()
        playerData.urlString = "https://meipu1.video.meipai.com/lo1fEs_fD8mS6aaqjILGocjsStg7"
        let playerDataDriver = Driver<AVPlayerData>.just(playerData)
        
        viewModel?.transform(input: PlayerContainerViewModel.Input.init(playerData: playerDataDriver)).playerData.drive(onNext: { (playerData) in
            self.playerView.playerData = playerData
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }
    
    override func loadViewModel() -> PlayerContainerViewModel? {
        return PlayerContainerViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(playerView)
        playerView.frame = CGRect(0, 200, self.view.width, 300)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

}




