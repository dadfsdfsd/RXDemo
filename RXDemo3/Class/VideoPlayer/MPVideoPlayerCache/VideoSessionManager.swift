//
//  SimpleSessionManager.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/12.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit


fileprivate struct Request {
    
    let urlRequest: URLRequest
    
    let delegate: URLSessionDataDelegate
}

class VideoSessionManager: NSObject, URLSessionDataDelegate {
    
    static let shared: VideoSessionManager = VideoSessionManager()
    
    var _session: URLSession?
    
    var session: URLSession {
        if _session == nil {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            _session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        }
        return _session!
    }
    
    private let lock = NSLock()
    private var requests: [Int: Request] = [:]
 
    
    private subscript(task: URLSessionTask) -> Request? {
        get {
            lock.lock() ; defer { lock.unlock() }
            return requests[task.taskIdentifier]
        }
        set {
            lock.lock() ; defer { lock.unlock() }
            requests[task.taskIdentifier] = newValue
        }
    }
    
    func dataTask(with request: URLRequest, delegate: URLSessionDataDelegate) -> URLSessionDataTask {
        let dataTask = session.dataTask(with: request)
        self[dataTask] = Request.init(urlRequest: request, delegate: delegate)
        return dataTask
    }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let delegate = self[dataTask]?.delegate {
            delegate.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let delegate = self[dataTask]?.delegate {
            delegate.urlSession?(session, dataTask: dataTask, didReceive: data)
            
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let delegate = self[task]?.delegate {
            delegate.urlSession?(session, task: task, didCompleteWithError: error)
        }
        self[task] = nil
    }
    
}


