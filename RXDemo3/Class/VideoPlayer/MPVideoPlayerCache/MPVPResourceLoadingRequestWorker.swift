//
//  MPResourceLoadingRequestWorker.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/8.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol MPVPResourceloadingRequestWorkerDelegate: class {
    func resourceLoadingRequestWorker(_ worker: MPVPResourceLoadingRequestWorker, didCompleteWithError: Error?)
}

enum MPVPResourceLoadingRequestWorkerError: Error {
    case FinishError
}

class MPVPResourceLoadingRequestWorker {

    var url: URL

    var request: AVAssetResourceLoadingRequest

    var downloader: MPVPDownloader

    weak var delegate: MPVPResourceloadingRequestWorkerDelegate? = nil

    init(with url: URL, request: AVAssetResourceLoadingRequest, configuration: MPVPCacheConfiguration, _ ioQueue: DispatchQueue) {
        self.url = url
        downloader = MPVPDownloader(with: url, configuration: configuration, ioQueue)
        self.request = request

        downloader.delegate = self
        fullfillContentInfo()
        startWork()
    }

    func startWork() {
        guard let dataRequest = request.dataRequest else { return }

        var offset: Int64 = dataRequest.requestedOffset
        let length = dataRequest.requestedLength
        if dataRequest.currentOffset != 0 {
            offset = dataRequest.currentOffset
        }

        var toEnd = false
        if #available(iOS 9.0, *) {
            if dataRequest.requestsAllDataToEndOfResource {
                toEnd = true
            }
        }

        downloader.downloadTask(from: offset, length: length, toEnd: toEnd)
    }

    func cancel() {
        downloader.cancel()
    }
    
    deinit {
        downloader.cancel()
    }

    fileprivate func finish(request: AVAssetResourceLoadingRequest) {

        if !request.isFinished {
            request.finishLoading(with: MPVPResourceLoadingRequestWorkerError.FinishError)
        }
    }

    fileprivate func fullfillContentInfo() {
        let contentInformationRequest = request.contentInformationRequest

        if contentInformationRequest?.contentType == nil && downloader.info.contentLength != 0 {
            contentInformationRequest?.isByteRangeAccessSupported = downloader.info.isByteRangeAccessSupported
            contentInformationRequest?.contentType = downloader.info.contentType
            contentInformationRequest?.contentLength = downloader.info.contentLength
        }
    }

    fileprivate func responseRequest(data: Data, range: Range<Int>) {
        guard request.dataRequest != nil else { return }
        if range.lowerBound != Int(request.dataRequest!.currentOffset) {
            print("dataResponse Error")
        }
        request.dataRequest!.respond(with: data)
    }
}

extension MPVPResourceLoadingRequestWorker: MPVPDownloaderDelegate {
    func downloader(_ downloader: MPVPDownloader, didReceive response: URLResponse) {
            fullfillContentInfo()
    }

    func downloader(_ downloader: MPVPDownloader, didReceive data: Data, for range: Range<Int>) {
        responseRequest(data: data, range: range)
    }

    func downloader(_ downloader: MPVPDownloader, didFinishedWithError error: Error?) {
        if error == nil {
            request.finishLoading()
        } else {
            request.finishLoading(with: error)
        }
            delegate?.resourceLoadingRequestWorker(self, didCompleteWithError: error)
    }
}
