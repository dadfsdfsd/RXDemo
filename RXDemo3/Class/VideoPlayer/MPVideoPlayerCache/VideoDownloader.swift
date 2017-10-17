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

enum VideoCacheDownloaderError: Error {
    case DownloadingURL
    case TaskError
}

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
protocol VideoDownloaderDelegate: class {
    func downloader(_ downloader: VideoDownloader, didReceive response: URLResponse)

    func downloader(_ downloader: VideoDownloader, didReceive data: Data, for range: Range<Int>)

    func downloader(_ downloader: VideoDownloader, didFinishedWithError error: Error?)
}

class VideoDownloader: NSObject {

    fileprivate var url: URL

    weak var delegate: VideoDownloaderDelegate? = nil

    fileprivate var cacheWorker: VideoCacheWorker
    fileprivate var unitWorker: VideoCacheUnitWorker? = nil
    var info: VideoCacheContentInfo

    fileprivate var ioQueue: DispatchQueue

    fileprivate var downloadToEnd = false

    init(with url: URL, configuration: VideoCacheConfiguration, _ ioQueue: DispatchQueue) {
        self.url = url
        cacheWorker = VideoCacheWorker(with: url, configuration: configuration, ioQueue)
        info = cacheWorker.internalCacheConfiguration.contentInfo
        self.ioQueue = ioQueue
    }
 
    func downloadTask(from offset: Int64, length: Int, toEnd: Bool) {

        var range: Range = Int(offset)..<(Int(offset)+length)

        if toEnd {
            let temp: Range = Int(range.lowerBound)..<(Int(cacheWorker.internalCacheConfiguration.contentInfo.contentLength)>0 ? Int(cacheWorker.internalCacheConfiguration.contentInfo.contentLength) : range.upperBound)
            range = temp
        }

        let units = self.cacheWorker.cacheUnits(from: range)

        self.unitWorker = VideoCacheUnitWorker(with: units, url: self.url, cacheWorker: self.cacheWorker, self.ioQueue)
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

        unitWorker = VideoCacheUnitWorker(with: units, url: url, cacheWorker: cacheWorker, ioQueue)
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
        delegate?.downloader(self, didFinishedWithError: VideoCacheDownloaderError.DownloadingURL)
    }

}

extension VideoDownloader: MPVPCacheUnitWorkerDelegate {

    func unitWorker(_ unitWorker: VideoCacheUnitWorker, didReceive response: URLResponse) {
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

    func unitWorker(_ unitWorker: VideoCacheUnitWorker, didReceive data: Data, for range: Range<Int>, isLocal: Bool) {
        delegate?.downloader(self, didReceive: data, for: range)
    }

    func unitWorker(_ unitWorker: VideoCacheUnitWorker, didFinishWithError error: Error?) {

        if error == nil && downloadToEnd {
            downloadToEnd = false
            downloadTask(from: 2, length: Int(cacheWorker.internalCacheConfiguration.contentInfo.contentLength) - 2, toEnd: true)
        } else {
            delegate?.downloader(self, didFinishedWithError: error)
        }
    }
}
