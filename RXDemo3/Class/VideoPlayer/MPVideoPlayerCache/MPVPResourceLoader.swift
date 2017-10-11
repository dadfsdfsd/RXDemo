//
//  MPVideoPlayerResourceLoader.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/2.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit


private enum MPVPResourceLoaderError: Error {
    case WrongURLComponents
    case WrongURLScheme
}

//MARK: - Class ResourceLoader
fileprivate protocol ResourceLoaderDelegate: class {
    func resourceLoader(_ resourceLoader: ResourceLoader, request: AVAssetResourceLoadingRequest, didFailWithError error: Error?)
}

class ResourceLoader: NSObject {

    fileprivate var url: URL
    
    weak fileprivate var delegate: ResourceLoaderDelegate? = nil

    fileprivate var loadingRequestWorkers: [AVAssetResourceLoadingRequest : MPVPResourceLoadingRequestWorker]

    var configuration: MPVPCacheConfiguration

    var ioQueue = DispatchQueue(label: "com.meitu.meipu.videoCache.ioQueue")

    init(with url: URL) {
        self.url = url
        let configurationPath = MPVPCacheConfiguration.videoCacheTemporaryPath(key: url.absoluteString)
        configuration = MPVPCacheConfiguration.configuration(with: configurationPath)
        configuration.url = url
        loadingRequestWorkers = [:]
    }

    deinit {
        cancelAll()
    }

    fileprivate func add(request: AVAssetResourceLoadingRequest) {
        if loadingRequestWorkers[request] == nil {
            let loadingRequestWorker = MPVPResourceLoadingRequestWorker(with: url, request: request, configuration: configuration, ioQueue)
            loadingRequestWorkers[request] = loadingRequestWorker
        }
    }

    func cancel(request: AVAssetResourceLoadingRequest) {
        guard let worker = loadingRequestWorkers[request] else { return }
        worker.cancel()
        loadingRequestWorkers.removeValue(forKey: request)
    }

    func cancelAll() {
        loadingRequestWorkers.removeAll()
    }
}

extension ResourceLoader: MPVPResourceloadingRequestWorkerDelegate {
    func resourceLoadingRequestWorker(_ worker: MPVPResourceLoadingRequestWorker, didCompleteWithError error: Error?) {
        if error != nil {
            delegate?.resourceLoader(self, request: worker.request, didFailWithError: error)
        }
    }
}



//MARK: - Class MPVPResourceLoader
protocol MPVPResourceLoaderDelegate: class {
    func resourceLoaderLoad(url: URL, didFailWithError error: Error?)
}

class MPVPResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    //MARK: - private property
    fileprivate let cacheScheme = "MPVideoPlayerCache"

    fileprivate var originScheme = "http"

    weak var delegate: MPVPResourceLoaderDelegate? = nil

    fileprivate var isCancel = false

    var loaders: [String: ResourceLoader] = [:]

    //MARK: - Public Method
    func playerItem(url: URL) -> AVPlayerItem {
        do {
            
            let assetURL = try replaceScheme(url: url)
            let urlAsset = AVURLAsset(url: assetURL)
            urlAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
            let playerItem = AVPlayerItem(asset: urlAsset)
            if #available(iOS 9.0, *) {
                playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            } else {
            }
            return playerItem

        } catch let error as NSError {
            print(error)
        }

        return AVPlayerItem(url: url)
    }

    func removeFor(url : URL) {
        loaders.removeValue(forKey: url.absoluteString)
    }

    func removeAllLoaders() {
        cancelAllLoaders()
        loaders.removeAll()
    }

    //MARK: - init
    override init() {
        super.init()
    }

    deinit {
        removeAllLoaders()
        MPVPCacheManager.sharedInstance.saveFileEntrys()
    }

    //MARK: - AVAssetResourceLoaderDelegate
    internal func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let resourceURL = loadingRequest.request.url else { return false }

        if resourceURL.scheme == cacheScheme {
            var loader = self.loader(for: loadingRequest)
            if loader == nil {
                do {
                    let originURL = try replaceScheme(url: resourceURL)

                    loader = ResourceLoader(with: originURL)
                    loader?.delegate = self
                    loaders[resourceURL.absoluteString] = loader!
                } catch let error as NSError {
                    print(error)
                }
            }
            loader?.add(request: loadingRequest)
            return true
        }
        return false
    }

    internal func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let loader = self.loader(for: loadingRequest) else { return }
        loader.cancel(request: loadingRequest)
    }

    //MARK: - Private Method
    fileprivate func cancelAllLoaders() {
        for (_, value) in loaders {
            value.cancelAll()
        }
    }

    fileprivate func replaceScheme(url: URL) throws -> URL {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw MPVPResourceLoaderError.WrongURLComponents
        }

        guard let scheme = components.scheme else {
            throw MPVPResourceLoaderError.WrongURLScheme
        }

        if scheme != cacheScheme {
            originScheme = scheme
            components.scheme = cacheScheme
        } else {
            components.scheme = originScheme
        }
        guard let assetURL = components.url else {
            throw MPVPResourceLoaderError.WrongURLComponents
        }
        return assetURL
    }

    fileprivate func loader(for request: AVAssetResourceLoadingRequest) -> ResourceLoader? {
        guard let key = request.request.url else { return nil }
        guard let loader = loaders[key.absoluteString] else { return nil }
        return loader
    }
}

extension MPVPResourceLoader: ResourceLoaderDelegate {
    fileprivate func resourceLoader(_ resourceLoader: ResourceLoader, request: AVAssetResourceLoadingRequest, didFailWithError error: Error?) {
        resourceLoader.cancel(request: request)
        delegate?.resourceLoaderLoad(url: resourceLoader.url, didFailWithError: error)
    }
}
