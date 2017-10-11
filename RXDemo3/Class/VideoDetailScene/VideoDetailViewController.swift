//
//  VideoDetailViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/11.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class VideoDetailViewModel: ViewModel {
    
    struct Input {
        let playerData: Driver<MPAVPlayerData>
    }
    
    struct Output {
        let playerData: Driver<MPAVPlayerData>
    }
    
    func transform(input: VideoDetailViewModel.Input) -> VideoDetailViewModel.Output {
        return Output.init(playerData: input.playerData)
    }
}


class VideoDetailViewController: BaseViewController<VideoDetailViewModel> {
    
    var player: WMPlayer = WMPlayer()
    
    override func didBind(to viewModel: VideoDetailViewModel?) {
        super.didBind(to: viewModel)
    
        let playerData = MPAVPlayerData()
        playerData.urlString = "https://meipu1.video.meipai.com/lo1fEs_fD8mS6aaqjILGocjsStg7"
        let playerDataDriver = Driver<MPAVPlayerData>.just(playerData)
        
        viewModel?.transform(input: VideoDetailViewModel.Input.init(playerData: playerDataDriver)).playerData.drive(onNext: { (playerData) in
            self.player.playerData = playerData
            self.player.play()
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }
    
    override func loadViewModel() -> VideoDetailViewModel? {
        return VideoDetailViewModel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(player)
        player.frame = CGRect.init(x: 0, y: 200, width: self.view.width, height: 400    )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
