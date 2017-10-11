//
//  MPPlayer.swift
//  Meipu
//
//  Created by Peter Jin on 2016/10/25.
//  Copyright © 2016年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import UIKit
import AVFoundation

protocol MPPlayerViewContainer:class {
    func addVideoView(_ videoView:MPPlayer)
    func removeVideoView()
    func playVideo()
    func testAutoPlay()
    func pauseVideo()
    func stopVideo()
}


class MPPlayer : WMPlayer {
   
    fileprivate var networkChangeView : UIView?
    fileprivate var networkChangeLabel : UILabel?
    fileprivate var networkChangeVideoDurationLabel : UILabel?
    fileprivate var networkChangeButton : UIButton?
    weak var container:MPPlayerViewContainer?
    var isStopByBackgroud : Bool = false
    
    override init(frame: CGRect, supportCache: Bool) {
        super.init(frame: frame, supportCache: supportCache)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error)
        }
        
        NotificationCenter.default.addObserver(self, selector:#selector(MPPlayer.handleNetChange), name: NSNotification.Name.MTNetworkingReachabilityDidChange, object: nil)
        
        //进入后台
        NotificationCenter.default.addObserver(self, selector: #selector(MPPlayer.didEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        //进入前台
        NotificationCenter.default.addObserver(self, selector: #selector(MPPlayer.didBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        //被打断，电话
        NotificationCenter.default.addObserver(self, selector: #selector(didPlaybackStalledOrInterrupt(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        //路由切换，挂了电话
        NotificationCenter.default.addObserver(self, selector: #selector(MPPlayer.didRouteChange(_:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)

    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.container = nil
    }
    
    override func resetWMPlayer() {
        super.resetWMPlayer()
        networkChangeView?.removeFromSuperview()
        networkChangeView = nil
    }
    
    fileprivate func showNetworkChangeView(withVideoDuration duraiton: String, currentTime: String) {
        if networkChangeView == nil {
            networkChangeView = UIButton()
        }
        guard let backView = networkChangeView else {
            return
        }
        
        backView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        self.addSubview(backView)
        backView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.finishView)
        }
       
        if networkChangeLabel == nil {
            networkChangeLabel = UILabel()
        }
        guard let label = networkChangeLabel else {
            return
        }
        
        if networkChangeVideoDurationLabel == nil {
            networkChangeVideoDurationLabel = UILabel()
        }
        
        guard let subLabel = networkChangeVideoDurationLabel else { return }

        label.text = "已切换到2G/3G/4G网络\n继续播放将会消耗您的流量"
        label.numberOfLines = 2
        label.textColor = UIColor.mpFFFFFFColor()
        label.font = UIFont.mpLightFontOfSize(16)
        label.textAlignment = .center
        backView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.equalTo(backView)
            make.bottom.equalTo(backView.snp.centerY).offset(-10)
        }

        let videoDuration = duraiton
        subLabel.text = (videoDuration != "") ? ("视频时长 " + currentTime + "/" + videoDuration) : ""
        subLabel.textColor = UIColor.mpFFFFFFColor()
        subLabel.font = UIFont.mpFontOfSize(13)
        backView.addSubview(subLabel)
        subLabel.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(5)
            make.centerX.equalTo(backView)
        }

        if networkChangeButton == nil {
            networkChangeButton = UIButton()
        }
        guard let button = networkChangeButton else {
            return
        }
        
        button.setTitle("继续观看", for: UIControlState())
        button.setTitleColor(UIColor.mpPinkColor(), for: UIControlState())
        button.titleLabel?.font = UIFont.mpFontOfSize(15)
        button.layer.cornerRadius = 4
        button.layer.borderColor = UIColor.mpPinkColor().cgColor
        button.layer.borderWidth = 0.5
        button.addTarget(self, action: #selector(MPPlayer.onContinue), for: .touchUpInside)
        backView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerX.equalTo(backView)
            make.top.equalTo(subLabel.snp.bottom).offset(12)
            make.size.equalTo(CGSize(120, 30))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func onContinue() {
        self.play()
        
        self.networkChangeView?.removeFromSuperview()
        self.networkChangeLabel = nil
        self.networkChangeButton = nil
        self.networkChangeView = nil
    }
    
    @objc func onReplay() {
        self.playOrPause(nil)
    }

    override func playOrPause(_ sender: UIButton!) {
        
        guard let data = self.playerData else { return }
        if data.canPlayWhenNotWifi{
            super.playOrPause(sender)
        }
        else{
            if MPPlayerManager.sharedInstance.needShowCellularAlert{
                if (self.isPlaying == false){
                    MPPlayerManager.sharedInstance.showCellularAlert({ () in
                        super.playOrPause(sender)
                    })
                    data.canPlayWhenNotWifi = true
                }
                else{
                    super.playOrPause(sender)
                }
            }
            else{
                super.playOrPause(sender)
            }
        }
    }
    
    
    @objc private func handleNetChange(){
        if MTNetworkReachabilityManager.shared().networkReachabilityStatus  == MTNetworkReachabilityStatus.reachableViaWWAN {
            if self.state == .buffering || self.state == .paused || self.state == .playing || self.state == .readyToPlay {
                let duration = self.videoDurationStr() 
                let currentTime = self.convertTime(second: CGFloat(self.currentTime()))
                self.suspend()
                showNetworkChangeView(withVideoDuration: duration, currentTime: currentTime)
            }
        }
    }
    
    @objc fileprivate func didPlaybackStalledOrInterrupt(_ notification: Notification) {
        self.pause()
    }
    
    @objc fileprivate func didRouteChange(_ notification: Notification) {
        //路由切换，插拔耳机
        if let userinfo = notification.userInfo {
            if let changeReason = userinfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //changeReason等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
                if changeReason == AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue {
                    if let descpt = userinfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                        if let port = descpt.outputs.first {
                            if port.portType == "Headphones" || port.portType.hasPrefix("Bluetooth") {
                                self.pause()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func didEnterBackground(){
        //home进入后台
        isStopByBackgroud = self.isPlaying
        self.pause()
    }
    
    @objc fileprivate func didBecomeActive(_ notification: Notification){
        //从后台进入前台
        if isStopByBackgroud {
            self.play()
        }
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}



