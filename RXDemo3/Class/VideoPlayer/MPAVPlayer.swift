//
//  MPAVPlayer.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/11.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate enum VideoCacheError: Error {
    case PathError
    
}

public func dispatch_main_async_safe(block: @escaping () -> ()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}


class MPAVPlayerData: NSObject {
    
    var size:CGSize = .zero
    
    var contextID:Int64 = 0
    
    var isMute:Bool = true
    
    var seekTime: CMTime = kCMTimeZero
    
    var autoPlayWhenNextAppear = true
    
    var isPausedByUser = false
    
    var canPlayWhenNotWifi:Bool = false;
    
    var urlString:String = ""

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init() {
        super.init()
        //        NotificationCenter.default.addObserver(self, selector: #selector(MPAVPlayerData.handleNetChange), name: NSNotification.Name.MTNetworkingReachabilityDidChange, object: nil)
    }
    
    @objc func handleNetChange(){
        self.canPlayWhenNotWifi = false
    }
    
    
    var player : MPAVPlayer? {
        guard let url = URL(string:urlString) else {
            return nil
        }
        
        let player = MPAVPlayer(url: url)
        
        player.volume = self.isMute ? 0 : 1
        
        return player
    }
    
    var layer : AVPlayerLayer? {
        
        let layer = AVPlayerLayer(player: self.player)
        return layer
    }
}

class MPAVPlayer:AVPlayer
{
    private let isUseCache = true
    private lazy var resourceLoader = MPVPResourceLoader()
    
    override init() {
        super.init()
        self.internalInit()
    }
    
    override init(url: URL) {
        super.init()
        self.internalInit()
        creatAVURLAsset(withUrl: url)
    }
    
    override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
        self.internalInit()
    }
    
    func internalInit(){
        //        http://www.jianshu.com/p/17df68e8f4ca
        if #available(iOS 10.0, *) {
            self.automaticallyWaitsToMinimizeStalling = false
        } else {
            // Fallback on earlier versions
        };
    }
    
    private func creatAVURLAsset(withUrl url: URL) {
        if !isUseCache {
            MPVPCacheManager.sharedInstance.clearDisk()
            resourceLoader.removeAllLoaders()
            self.replaceCurrentItem(with: AVPlayerItem(asset: AVAsset(url: url)))
            return
        }
        MPVPCacheManager.sharedInstance.queryCache(key: url) { [weak self] videoPath in
            guard let `self` = self else { return }
            if videoPath != nil {
                do {
                    try self.playExistedVideo(url: url, fullVideoCachePath: videoPath)
                } catch {
                    print(error)
                }
            } else {
                self.replaceCurrentItem(with: self.resourceLoader.playerItem(url: url))
            }
        }
    }
    
    private func playExistedVideo(url: URL, fullVideoCachePath: String?) throws {
        guard let fullVideoCachePath = fullVideoCachePath, fullVideoCachePath.length != 0 else { throw VideoCacheError.PathError }
        
        let videoPathURL = URL(fileURLWithPath: fullVideoCachePath)
        
        self.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: videoPathURL, options: nil)))
    }
    
    deinit {
        print("MPAVPlayer deinit")
    }
}

class AVPlayerView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        (self.layer as? AVPlayerLayer)?.player = player
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

