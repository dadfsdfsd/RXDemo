//
//  ResourceLoader.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/13.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import AVFoundation


protocol ResourceLoaderDelegate: class {
    func resourceLoader(_ resourceLoader: ResourceLoader, request: AVAssetResourceLoadingRequest, didFailWithError error: Error?)
}


class ResourceLoader: NSObject {
    
    var url: URL
    
    weak var resourceLoaderManager: AVResourceLoaderManager?
    
    weak var delegate: ResourceLoaderDelegate? = nil
    
    fileprivate var loadingRequestWorkers: [AVAssetResourceLoadingRequest : VideoResourceLoadingRequestWorker]
    
    var configuration: VideoCacheConfiguration
    
    var ioQueue = DispatchQueue(label: "com.meitu.meipu.videoCache.ioQueue")
    
    init(with url: URL) {
        self.url = url
        let configurationPath = VideoCacheConfiguration.videoCacheTemporaryPath(key: url.absoluteString)
        configuration = VideoCacheConfiguration.configuration(with: configurationPath)
        configuration.url = url
        loadingRequestWorkers = [:]
    }
    
    deinit {
        cancelAll()
    }
    
    func add(request: AVAssetResourceLoadingRequest) {
        if loadingRequestWorkers[request] == nil {
            let loadingRequestWorker = VideoResourceLoadingRequestWorker(with: url, request: request, configuration: configuration, ioQueue)
            loadingRequestWorkers[request] = loadingRequestWorker
        }
    }
    
    func cancel(request: AVAssetResourceLoadingRequest) {
        guard let worker = loadingRequestWorkers[request] else { return }
        worker.cancel()
        loadingRequestWorkers.removeValue(forKey: request)
    }
    
    func removeFromResourceManager() {
        resourceLoaderManager?.removeFor(url: self.url)
    }
    
    func cancelAll() {
        loadingRequestWorkers.removeAll()
    }
}

extension ResourceLoader: MPVPResourceloadingRequestWorkerDelegate {
    func resourceLoadingRequestWorker(_ worker: VideoResourceLoadingRequestWorker, didCompleteWithError error: Error?) {
        if error != nil {
            delegate?.resourceLoader(self, request: worker.request, didFailWithError: error)
        }
    }
}
