//
//  VideoCacheSessionDelegateObject.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/13.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

protocol VideoURLSessionDelegateObjectDelegate: class {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
}

class VideoSessionDelegateObject: NSObject {
    
    weak fileprivate var delegate: VideoURLSessionDelegateObjectDelegate?
    fileprivate var bufferData: Data
    fileprivate let kBufferSize = 20 * 1024     // to reduce IO
    
    init(with delegate: VideoURLSessionDelegateObjectDelegate) {
        self.delegate = delegate
        bufferData = Data()
        super.init()
    }
    
    deinit {
        debug_print("MPVPURLSessionDelegateObject deinit")
    }
}

extension VideoSessionDelegateObject: URLSessionDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if response.isKind(of: HTTPURLResponse.self) {
            if (response as! HTTPURLResponse).statusCode < 400 && (response as! HTTPURLResponse).statusCode != 304 {
                delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        self.bufferData.append(data)
        if self.bufferData.count > kBufferSize {
            let chunkRange: Range = 0..<self.bufferData.count
            let chunkData = self.bufferData.subdata(in: chunkRange)
            var nilPoint: AnyObject? = nil
            self.bufferData.replaceSubrange(chunkRange, with: &nilPoint, count: 0)
            delegate?.urlSession(session, dataTask: dataTask, didReceive: chunkData)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if self.bufferData.count > 0 && error == nil {
            let chunkRange: Range = 0..<self.bufferData.count
            let chunkData = self.bufferData.subdata(in: chunkRange)
            var nilPoint: AnyObject? = nil
            guard let task: URLSessionDataTask = task as? URLSessionDataTask else {
                return
            }
            self.bufferData.replaceSubrange(chunkRange, with: &nilPoint, count: 0)
            self.delegate?.urlSession(session, dataTask: task, didReceive: chunkData)
        }
        
        delegate?.urlSession(session, task: task, didCompleteWithError: error)
    }
}
