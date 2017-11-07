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


class PlayerContainerViewController: BaseViewController<PlayerContainerViewModel> {
    
    var player: PlayerView = PlayerView()
 
    
    override func didBind(to viewModel: PlayerContainerViewModel?) {
        super.didBind(to: viewModel)
        
        let playerData = AVPlayerData()
        playerData.urlString = "https://meipu1.video.meipai.com/lo1fEs_fD8mS6aaqjILGocjsStg7"
        let playerDataDriver = Driver<AVPlayerData>.just(playerData)
        
        viewModel?.transform(input: PlayerContainerViewModel.Input.init(playerData: playerDataDriver)).playerData.drive(onNext: { (playerData) in
            self.player.url = URL(string: playerData.urlString)!
            //            self.player2.playerData = playerData
            //            self.player2.play()
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }
    
    override func loadViewModel() -> PlayerContainerViewModel? {
        return PlayerContainerViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.player.playerDelegate = self
        self.player.playbackDelegate = self
        self.player.view.frame = self.view.bounds
        self.player.layerBackgroundColor = UIColor.white
        
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMove(toParentViewController: self)
        
        self.player.playbackLoops = false
        
//        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
//        tapGestureRecognizer.numberOfTapsRequired = 1
//        self.player.view.addGestureRecognizer(tapGestureRecognizer)
 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension PlayerContainerViewController: PlayerDelegate {
    
    func playerReady(_ player: PlayerView) {
    }
    
    func playerPlaybackStateDidChange(_ player: PlayerView) {
    }
    
    func playerBufferingStateDidChange(_ player: PlayerView) {
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
    }
    
}

// MARK: - PlayerPlaybackDelegate

extension PlayerContainerViewController: PlayerPlaybackDelegate {
    
    func playerCurrentTimeDidChange(_ player: PlayerView) {
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: PlayerView) {
    }
    
    func playerPlaybackDidEnd(_ player: PlayerView) {
    }
    
    func playerPlaybackWillLoop(_ player: PlayerView) {
    }
    
}



