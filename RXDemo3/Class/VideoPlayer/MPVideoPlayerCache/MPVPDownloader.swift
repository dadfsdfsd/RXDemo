//
//  MPVideoPlayerDownloader.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/7.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import MobileCoreServices

fileprivate let downloadTimeout: TimeInterval = 10

enum MPVPDownloaderError: Error {
    case DownloadingURL
    case TaskError
}

//MARK: - Class: MPVPURLSessionDelegateObject

protocol MPVPURLSessionDelegateObjectDelegate: class {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
}

class MPVPURLSessionDelegateObject: NSObject {

    weak fileprivate var delegate: MPVPURLSessionDelegateObjectDelegate?
    fileprivate var bufferData: Data
    fileprivate var _lock = MutexLock(.Recursive)
    fileprivate let kBufferSize = 20 * 1024     // to reduce IO

    init(with delegate: MPVPURLSessionDelegateObjectDelegate) {
        self.delegate = delegate
        bufferData = Data()
        super.init()
    }

    deinit {
         print("MPVPURLSessionDelegateObject deinit")
    }
}

extension MPVPURLSessionDelegateObject: URLSessionDelegate, URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if response.isKind(of: HTTPURLResponse.self) {
            if (response as! HTTPURLResponse).statusCode < 400 && (response as! HTTPURLResponse).statusCode != 304 {
                delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        _lock.run {
            self.bufferData.append(data)
            if self.bufferData.count > kBufferSize {
                let chunkRange: Range = 0..<self.bufferData.count
                let chunkData = self.bufferData.subdata(in: chunkRange)
                var nilPoint: AnyObject? = nil
                self.bufferData.replaceSubrange(chunkRange, with: &nilPoint, count: 0)
                delegate?.urlSession(session, dataTask: dataTask, didReceive: chunkData)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        _lock.run {
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
        }

        delegate?.urlSession(session, task: task, didCompleteWithError: error)
    }
}

//MARK: - Class: MPVPCacheUnitWorker

protocol MPVPCacheUnitWorkerDelegate: class {
    func unitWorker(_ unitWorker: MPVPCacheUnitWorker, didReceive response: URLResponse)

    func unitWorker(_ unitWorker: MPVPCacheUnitWorker, didReceive data: Data, for range: Range<Int>, isLocal: Bool)

    func unitWorker(_ unitWorker: MPVPCacheUnitWorker, didFinishWithError error: Error?)
}


class MPVPCacheUnitWorker: NSObject {

    // remote data request offset
    fileprivate var startOffset = 0
    fileprivate var cacheUnits: [MPVPCacheUnit]
    fileprivate var url: URL
    fileprivate var cacheWorker: MPVPCacheWorker
    weak var delegate: MPVPCacheUnitWorkerDelegate? = nil
    fileprivate var isCancel = false

    fileprivate var task: URLSessionDataTask? = nil

    fileprivate var ioQueue: DispatchQueue

    var notifyTime: TimeInterval = 0

    fileprivate var session: URLSession {
        get {
            if sessionTemp == nil {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = downloadTimeout
                sessionTemp = URLSession(configuration: configuration, delegate: sessionDelegateObject, delegateQueue: OperationQueue.main)

            }
            return sessionTemp!
        }
    }
    private var sessionTemp: URLSession? = nil

    fileprivate var sessionDelegateObject: MPVPURLSessionDelegateObject {
        get {
            if sessionDelegateObjectTemp == nil {
                sessionDelegateObjectTemp = MPVPURLSessionDelegateObject(with: self)
            }
            return sessionDelegateObjectTemp!
        }
    }
    private var sessionDelegateObjectTemp: MPVPURLSessionDelegateObject? = nil

    deinit {
        cancel()
    }

    init(with cacheUnits: [MPVPCacheUnit], url: URL, cacheWorker: MPVPCacheWorker, _ ioQueue: DispatchQueue) {
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
        if sessionTemp != nil {
            session.invalidateAndCancel()
        }
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
                    print(error!)
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
            task = session.dataTask(with: request)
            task!.resume()
        }
    }
}

extension MPVPCacheUnitWorker: MPVPURLSessionDelegateObjectDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

            delegate?.unitWorker(self, didReceive: response)

            cacheWorker.startWritting()

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

        cacheWorker.finishWritting()

        self.cacheWorker.save()


        if error != nil {
            self.delegate?.unitWorker(self, didFinishWithError: error)
        } else {
            self.processUnits()
        }

    }
}

//MARK: - Class: MPVPDownloaderStatus
class MPVPDownloaderStatus {
    static let sharedInstance = MPVPDownloaderStatus()

    var downloadingURLS: Set<URL> = Set()

    fileprivate var _lock = MutexLock()

    fileprivate func add(url: URL) {
        _lock.run {
            downloadingURLS.insert(url)
        }
    }

    fileprivate func remove(url: URL) {
        _lock.run {
            downloadingURLS.remove(url)
        }
    }

    fileprivate func contains(url: URL) -> Bool {
        var bool = false
        _lock.run {
            bool = downloadingURLS.contains(url)
        }
        return bool
    }

    func removeAll() {
        _lock.run {
            downloadingURLS.removeAll()
        }
    }
}

//MARK: - Class: MPVPDownloader
protocol MPVPDownloaderDelegate: class {
    func downloader(_ downloader: MPVPDownloader, didReceive response: URLResponse)

    func downloader(_ downloader: MPVPDownloader, didReceive data: Data, for range: Range<Int>)

    func downloader(_ downloader: MPVPDownloader, didFinishedWithError error: Error?)
}

class MPVPDownloader: NSObject {

    fileprivate var url: URL

    weak var delegate: MPVPDownloaderDelegate? = nil

    fileprivate var cacheWorker: MPVPCacheWorker
    fileprivate var unitWorker: MPVPCacheUnitWorker? = nil
    var info: MPVPContentInfo

    fileprivate var ioQueue: DispatchQueue
    fileprivate var _lock = MutexLock(.Recursive)

    fileprivate var downloadToEnd = false

    init(with url: URL, configuration: MPVPCacheConfiguration, _ ioQueue: DispatchQueue) {
        self.url = url
        cacheWorker = MPVPCacheWorker(with: url, configuration: configuration, ioQueue)
        info = cacheWorker.internalCacheConfiguration.contentInfo
        self.ioQueue = ioQueue
    }

    deinit {
    }

    //MARK: - Public
    func downloadTask(from offset: Int64, length: Int, toEnd: Bool) {

        var range: Range = Int(offset)..<(Int(offset)+length)

        if toEnd {
            let temp: Range = Int(range.lowerBound)..<(Int(cacheWorker.internalCacheConfiguration.contentInfo.contentLength)>0 ? Int(cacheWorker.internalCacheConfiguration.contentInfo.contentLength) : range.upperBound)
            range = temp
        }

        let units = self.cacheWorker.cacheUnits(from: range)

        self.unitWorker = MPVPCacheUnitWorker(with: units, url: self.url, cacheWorker: self.cacheWorker, self.ioQueue)
        self.unitWorker?.delegate = self
        self.unitWorker?.start()
    }

    func downloadFromStartToEnd() {
        if MPVPDownloaderStatus.sharedInstance.contains(url: url) {
            handleCurrentDownloadingError()
            return
        }

        MPVPDownloaderStatus.sharedInstance.add(url: url)

        downloadToEnd = true
        let range: Range = 0..<2
        let units = cacheWorker.cacheUnits(from: range)

        unitWorker = MPVPCacheUnitWorker(with: units, url: url, cacheWorker: cacheWorker, ioQueue)
        unitWorker?.delegate = self
        unitWorker?.start()
    }

    func cancel() {
        unitWorker?.cancel()
        unitWorker?.delegate = nil
        unitWorker = nil
    }

    func invalidateAndCancel() {
        unitWorker?.cancel()
        unitWorker?.delegate = nil
        unitWorker = nil
    }

    fileprivate func handleCurrentDownloadingError() {
        delegate?.downloader(self, didFinishedWithError: MPVPDownloaderError.DownloadingURL)
    }

}

extension MPVPDownloader: MPVPCacheUnitWorkerDelegate {

    func unitWorker(_ unitWorker: MPVPCacheUnitWorker, didReceive response: URLResponse) {
        _lock.run {
            if response.isKind(of: HTTPURLResponse.self) {
                let HTTPResponse: HTTPURLResponse = response as! HTTPURLResponse
                guard let acceptRange = HTTPResponse.allHeaderFields["Accept-Ranges"] as? String, let contentLength = Int64(((HTTPResponse.allHeaderFields["Content-Range"] as? String)?.components(separatedBy: "/").last!)!) else { return }

                self.info.contentLength = contentLength
                self.cacheWorker.internalCacheConfiguration.expectedSize = contentLength
                self.info.isByteRangeAccessSupported = (acceptRange == "Bytes")
            }
            var mimeType: CFString? = response.mimeType as CFString?
            if mimeType == nil {
                mimeType = "video/mp4" as CFString
            }
            self.info.contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType!, nil)!.takeUnretainedValue() as String

            self.cacheWorker.setFile()
            
            self.delegate?.downloader(self, didReceive: response)
        }
    }

    func unitWorker(_ unitWorker: MPVPCacheUnitWorker, didReceive data: Data, for range: Range<Int>, isLocal: Bool) {
        delegate?.downloader(self, didReceive: data, for: range)
    }

    func unitWorker(_ unitWorker: MPVPCacheUnitWorker, didFinishWithError error: Error?) {

        if error == nil && downloadToEnd {
            downloadToEnd = false
            downloadTask(from: 2, length: Int(cacheWorker.internalCacheConfiguration.contentInfo.contentLength) - 2, toEnd: true)
        } else {
            delegate?.downloader(self, didFinishedWithError: error)
        }
    }
}
