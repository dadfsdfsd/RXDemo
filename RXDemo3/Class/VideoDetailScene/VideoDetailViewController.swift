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
        let playerData: Driver<AVPlayerData>
    }
    
    struct Output {
        let playerData: Driver<AVPlayerData>
    }
    
    func transform(input: VideoDetailViewModel.Input) -> VideoDetailViewModel.Output {
        return Output.init(playerData: input.playerData)
    }
}


class VideoDetailViewController: BaseViewController<VideoDetailViewModel> {
    
    var player: WMPlayer = WMPlayer()
    var player2: WMPlayer = WMPlayer()
    
    override func didBind(to viewModel: VideoDetailViewModel?) {
        super.didBind(to: viewModel)
    
        let playerData = AVPlayerData()
        playerData.urlString = "https://meipu1.video.meipai.com/lo1fEs_fD8mS6aaqjILGocjsStg7"
        let playerDataDriver = Driver<AVPlayerData>.just(playerData)
        
        viewModel?.transform(input: VideoDetailViewModel.Input.init(playerData: playerDataDriver)).playerData.drive(onNext: { (playerData) in
            self.player.playerData = playerData
            self.player.play()
            
//            self.player2.playerData = playerData
//            self.player2.play()
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }
    
    override func loadViewModel() -> VideoDetailViewModel? {
        return VideoDetailViewModel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(player)
        player.frame = CGRect.init(x: 0, y: 100, width: self.view.width, height: 200)
        
//        self.view.addSubview(player2)
//        player2.frame = CGRect.init(x: 0, y: 400, width: self.view.width, height: 200)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
