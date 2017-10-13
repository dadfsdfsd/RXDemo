//
//  CacheableAVPlayer.swift
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

class CacheableAVPlayer:AVPlayer
{
    var isUseCache = true
    private lazy var resourceLoaderManager = AVResourceLoaderManager()
    
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
            self.replaceCurrentItem(with: AVPlayerItem(asset: AVAsset(url: url)))
            return
        }
        resourceLoaderManager.setupPlayer(player: self, withURL: url)
    }
    
    deinit {
        debug_print("MPAVPlayer deinit")
    }
}
