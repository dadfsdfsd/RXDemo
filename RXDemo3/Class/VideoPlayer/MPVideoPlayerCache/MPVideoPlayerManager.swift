//
//  VideoPlayerManager.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/2.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
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
class MPVideoPlayerManager: NSObject {

//    lazy fileprivate var resourceLoader = MPVPResourceLoader()

    //MARK: - Public
    func creatAVURLAsset(url: URL, player: AVPlayer) {
//        MPVPCacheManager.sharedInstance.clearDisk()
//        MPVPResourceLoader.sharedInstance.removeAllLoaders()
        MPVPCacheManager.sharedInstance.queryCache(key: url) { [weak self] videoPath in
            guard let `self` = self else { return }
            if videoPath != nil {
                do {
                    try self.playExistedVideo(url: url, fullVideoCachePath: videoPath, player: player)
                } catch {
                    print(error)
                }
            } else {
                player.replaceCurrentItem(with: MPVPResourceLoader.sharedInstance.playerItem(url: url))
            }
        }


    }

    func playExistedVideo(url: URL, fullVideoCachePath: String?, player: AVPlayer?) throws {
        guard let fullVideoCachePath = fullVideoCachePath, fullVideoCachePath.length != 0 else { throw VideoCacheError.PathError }

        let videoPathURL = URL(fileURLWithPath: fullVideoCachePath)
//        do {
//            let readFile = try FileHandle(forReadingFrom: videoPathURL)
//            let data = readFile.readDataToEndOfFile()
//            print(data)
//            readFile.closeFile()
//        } catch let error {
//            print(error)
//        }

        player?.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: videoPathURL, options: nil)))
    }
}

