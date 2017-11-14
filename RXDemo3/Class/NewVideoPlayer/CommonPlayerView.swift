                                                                                                                                                                                                      //
//  CommonPlayerView.swift
//  RXDemo3
//
//  Created by fan yang on 2017/11/8.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia


class CommonPlayerView: UIView {
    
    var playerData: AVPlayerData? {
        didSet {
            if let playerData = playerData {
                setupPlayerData(playerData)
            }
        }
    }
    
    lazy var playerFinishedView: PlayerFinishedView = {
        let view = PlayerFinishedView()
        view.delegate = self
        return view
    }()
    
    
    lazy var playerFailedView: PlayerFailedView = {
        let view = PlayerFailedView()
        view.delegate = self
        return view
    }()
    
    lazy var playerView: PlayerView = {
        let view = PlayerView()
        return view
    }()
    
    lazy var coverView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var controlView: PlayerControlView = {
        let view = PlayerControlView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPlayerData(_ playData: AVPlayerData) {
        playerView.playerData = playData
        if let coverUrlString = playerData?.coverUrlString, let url = URL(string: coverUrlString) {
            coverView.setImageWith(url, placeholder: nil)
        }
    }
    
    func setupSubviews() {
        setupPlayerView()
        setupCoverView()
        setupControlView()
        setupFinishedView()
        setupFailedView()
    }
    
    func setupFinishedView() {
        addSubview(playerFinishedView)
        
        playerFinishedView.isHidden = true
    }
    
    func setupFailedView() {
        addSubview(playerFailedView)
        
        playerFailedView.isHidden = true
    }
    
    func setupCoverView() {
        addSubview(coverView)
        
        coverView.isHidden = false
    }
    
    func setupPlayerView() {
        addSubview(playerView)
        
        playerView.playerDelegate = self
        playerView.playbackDelegate = self
        playerView.layerBackgroundColor = UIColor.white
    }
    
    private var seekingCount = 0
    
    var isInSeeking: Bool {
        return seekingCount > 0
    }
    
    func setupControlView() {
        addSubview(controlView)
        
        controlView.isPlaying.registerValueChange {[weak self] (newValue, oldValue) in
            if newValue {
                self?.playerView.playFromCurrentTime()
            }
            else {
                self?.playerView.pause()
            }
        }
        
        controlView.isMute.registerValueChange {[weak self] (newValue, oldValue) in
            self?.playerView.muted = newValue
        }
        
        controlView.isFullScreen.registerValueChange {[weak self] (newValue, oldValue) in
            if newValue {
                self?.toFullScreen()
            }
            else {
                self?.toSmallScreen()
            }
        }
        
        controlView.seekToTime.registerValueChange {[weak self] (newValue, oldValue) in
            self?.seekingCount += 1
            self?.playerView.seek(to: CMTime(value: CMTimeValue(newValue), timescale: 1), completionHandler: {[weak self] (finished) in
                self?.seekingCount -= 1
            })
        }
    }
    
    var smallFrame: CGRect?
    
    var originSuperView: UIView?
    
    var animationDuration: TimeInterval = 0.25
    
    func toFullScreen() {
        originSuperView = self.superview
        UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.fade)
        smallFrame = self.frame
        self.removeFromSuperview()
        
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            guard let `self` = self else { return }
            let rect = CGRect(x: kScreenWidth/2 - kScreenHeight/2, y: kScreenHeight/2 - kScreenWidth/2, width: kScreenHeight, height: kScreenWidth)
            self.frame = rect
            self.transform = CGAffineTransform(rotationAngle: .pi/2)
            self.layoutIfNeeded()
            }, completion: nil)
    }
    
    func toSmallScreen() {
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.none)
        
        originSuperView?.viewController()?.view.setNeedsLayout()
        
        removeFromSuperview()
        originSuperView?.addSubview(self)
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.transform = CGAffineTransform.identity
            self.frame = self.smallFrame ?? .zero
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.playerView.frame = self.bounds
        self.controlView.frame = self.bounds
        self.coverView.frame = self.bounds
        self.playerFinishedView.frame = self.bounds
        self.playerFailedView.frame = self.bounds
    }
}

extension CommonPlayerView: PlayerDelegate {
    
    func playerReady(_ player: PlayerView) {
        controlView.maximumDuration.value = Float(player.maximumDuration)
        coverView.isHidden = true
    }
    
    func executeClosureOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }
    
    func playerPlaybackStateDidChange(_ player: PlayerView) {
        self.executeClosureOnMainQueueIfNecessary {
            self.onPlayerStateChange(to: player.playbackState)
        }
    }
    
    func onPlayerStateChange(to state: PlaybackState) {
        switch state {
        case .playing:
            controlView.isPlaying.value = true
            coverView.isHidden = true
            playerFailedView.isHidden = true
            controlView.isHidden = false
            playerFinishedView.isHidden = true
            
        case .failed:
            controlView.isPlaying.value = false
            coverView.isHidden = false
            playerFailedView.isHidden = false
            controlView.isHidden = true
            playerFinishedView.isHidden = true
            
        case .stopped:
            controlView.isPlaying.value = false
            coverView.isHidden = true
            playerFailedView.isHidden = true
            controlView.isHidden = true
            
        case .paused:
            controlView.isPlaying.value = false
            coverView.isHidden = true
            playerFailedView.isHidden = true
            controlView.isHidden = false
            playerFinishedView.isHidden = true
        }
    }
    
    func playerBufferingStateDidChange(_ player: PlayerView) {
        switch player.bufferingState {
        case .delayed:
            controlView.isBuffering.value = true
        case .ready:
            controlView.isBuffering.value = false
        case .unknown:
            break
        }
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
        
    }
    
}

extension CommonPlayerView: PlayerPlaybackDelegate {
    
    func playerCurrentTimeDidChange(_ player: PlayerView) {
        if !isInSeeking {
            controlView.currentTime.value = Float(player.currentTime)
        }
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: PlayerView) {
        
    }
    
    func playerPlaybackDidEnd(_ player: PlayerView, finished: Bool) {
        if finished {
            playerFinishedView.isHidden = false
        }
    }
    
    func playerPlaybackWillLoop(_ player: PlayerView) {
        
    }
    
}

extension CommonPlayerView: PlayerFailedViewDelegate {
    
    func retryPlay() {
        setupSubviews()
        if let playerData = self.playerData {
            setupPlayerData(playerData)
        }
    }
}

extension CommonPlayerView: PlayerFinishedViewDelegate {
    
    func playFromBeginning() {
        self.playerView.playFromBeginning()
    }
    
 
}
