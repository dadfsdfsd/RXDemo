//
//  VideoCacheUnitWorker.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/13.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

protocol MPVPCacheUnitWorkerDelegate: class {
    func unitWorker(_ unitWorker: VideoCacheUnitWorker, didReceive response: URLResponse)
    
    func unitWorker(_ unitWorker: VideoCacheUnitWorker, didReceive data: Data, for range: Range<Int>, isLocal: Bool)
    
    func unitWorker(_ unitWorker: VideoCacheUnitWorker, didFinishWithError error: Error?)
}


class VideoCacheUnitWorker: NSObject {
    
    weak var delegate: MPVPCacheUnitWorkerDelegate? = nil
    // remote data request offset
    private var startOffset = 0
    
    private var cacheUnits: [VideoCacheUnit]
    
    private var url: URL
    
    private var cacheWorker: VideoCacheWorker
    
    private var isCancel = false
    
    private var task: URLSessionDataTask? = nil
    
    private var ioQueue: DispatchQueue
    
    var notifyTime: TimeInterval = 0
    
    private var _sessionDelegateObject: VideoSessionDelegateObject? = nil
    
    private var sessionDelegateObject: VideoSessionDelegateObject {
        get {
            if _sessionDelegateObject == nil {
                _sessionDelegateObject = VideoSessionDelegateObject(with: self)
            }
            return _sessionDelegateObject!
        }
    }
    
    deinit {
        cancel()
    }
    
    init(with cacheUnits: [VideoCacheUnit], url: URL, cacheWorker: VideoCacheWorker, _ ioQueue: DispatchQueue) {
        self.cacheUnits = cacheUnits
        self.url = url
        self.cacheWorker = cacheWorker
        self.ioQueue = ioQueue
        super.init()
    }
    
    func start() {
        processUnits()
    }
    
    func cancel() {
        task?.cancel()
        isCancel = true
    }
    
    fileprivate func processUnits() {
        if isCancel { return }
        
        guard let cacheUnit = cacheUnits.first else {
            delegate?.unitWorker(self, didFinishWithError: nil)
            return
        }
        
        cacheUnits.remove(at: 0)
        
        if cacheUnit.strategy == .Local {
            
            cacheWorker.cachedData(from: cacheUnit.range) { (data, error) in
                guard let data = data else { return }
                if error == nil {
                    self.delegate?.unitWorker(self, didReceive: data, for: cacheUnit.range, isLocal: true)
                    self.processUnits()
                    
                } else {
                    debug_print(error!)
                    self.delegate?.unitWorker(self, didFinishWithError: error)
                }
            }
        } else {
            
            let fromOffset = cacheUnit.range.lowerBound
            let endOffset = cacheUnit.range.upperBound-1
            var request: URLRequest = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let range = "bytes=\(fromOffset)-\(endOffset)"
            request.setValue(range, forHTTPHeaderField: "Range")
            startOffset = cacheUnit.range.lowerBound
            task =  VideoSessionManager.shared.dataTask(with: request, delegate: sessionDelegateObject)
            task!.resume()
        }
    }
}

extension VideoCacheUnitWorker: VideoURLSessionDelegateObjectDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        delegate?.unitWorker(self, didReceive: response)
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if isCancel { return }
        
        let range: Range = self.startOffset..<(self.startOffset+data.count)
        do {
            try self.cacheWorker.cache(data: data, for: range)
            
            self.startOffset += data.count
            self.delegate?.unitWorker(self, didReceive: data, for: range, isLocal: false)
        } catch let error {
            self.delegate?.unitWorker(self, didFinishWithError: error)
            return
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        if error != nil {
            self.delegate?.unitWorker(self, didFinishWithError: error)
        } else {
            self.processUnits()
        }
        
    }
}
