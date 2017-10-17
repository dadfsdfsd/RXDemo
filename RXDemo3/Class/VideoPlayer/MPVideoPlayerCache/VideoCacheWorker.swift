//
//  MPVideoPlayerCacheWorker.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/8.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation

enum VideoCacheWorkerError: Error {
    case FileHandleNil
    case Unknown
}

let kPackageLength = 204800

class VideoCacheWorker: NSObject {

    private var readFileHandle: FileHandle? = nil
    private var writeFileHandle: FileHandle? = nil
    private var writeBytes = 0
    private let filePath: String
    private let url: URL
    private var ioQueue: DispatchQueue
    
    private(set) var internalCacheConfiguration: VideoCacheConfiguration = VideoCacheConfiguration()

    //MARK: - Public
    init(with url: URL, configuration: VideoCacheConfiguration, _ ioQueue: DispatchQueue) {
        self.ioQueue = ioQueue
        let path = VideoCacheConfiguration.videoCacheTemporaryPath(key: url.absoluteString)
        self.url = url
        filePath = path
        internalCacheConfiguration = configuration
        let fileURL = URL(fileURLWithPath: path)

        do {
            readFileHandle = try FileHandle(forReadingFrom: fileURL)
            writeFileHandle = try FileHandle(forWritingTo: fileURL)
        } catch {
            debug_print(error)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        readFileHandle?.closeFile()
        writeFileHandle?.closeFile()
    }


    // store data for range
    func cache(data: Data, for range: Range<Int>) throws {
        guard let writeFileHandle = self.writeFileHandle else {
            throw VideoCacheWorkerError.FileHandleNil
        }
        ioQueue.async {
            writeFileHandle.seek(toFileOffset: UInt64(range.lowerBound))
            writeFileHandle.write(data)
            self.save()
            DispatchQueue.main.async {
                self.internalCacheConfiguration.add(cacheFragment: range)
                self.writeBytes += data.count
                self.ioQueue.async {
                    self.internalCacheConfiguration.save()
                }
                if self.internalCacheConfiguration.expectedSize == self.internalCacheConfiguration.receivedSize {
                    debug_print("receive complete")
                }
            }
        }
    }

    // get cacheUnits(wthere local or remote) from range
    func cacheUnits(from range: Range<Int>) -> [VideoCacheUnit] {
        var units: [VideoCacheUnit] = []

        if range.lowerBound == Int.max { return units }

        let upperBound = range.upperBound

        let cachedFragments = internalCacheConfiguration.fragments

        for i in 0..<cachedFragments.count {
            let fragmentRange = cachedFragments[i]
            let intersectionRange = range.clamped(to: fragmentRange)
            if intersectionRange.count > 0 {
                let package: Int = intersectionRange.count / kPackageLength
                for j in 0...package {
                    let offset = j*kPackageLength
                    let offsetLowerBound = intersectionRange.lowerBound+offset
                    let length = (offsetLowerBound+kPackageLength) > intersectionRange.upperBound ? (intersectionRange.upperBound - offsetLowerBound) : kPackageLength

                    units.append(VideoCacheUnit(with: .Local, range: offsetLowerBound..<(offsetLowerBound+length)))
                }
            } else if fragmentRange.lowerBound >= upperBound {
                break
            }
        }

        if units.count == 0 {
            units.append(VideoCacheUnit(with: .Remote, range: range))
        } else {
            var localRemoteUnits: [VideoCacheUnit] = []
            for i in 0..<units.count {
                let unitRange = units[i].range
                if i == 0 {
                    if range.lowerBound < unitRange.lowerBound {
                        localRemoteUnits.append(VideoCacheUnit(with: .Remote, range: range.lowerBound..<unitRange.lowerBound))
                    }
                    localRemoteUnits.append(units[i])
                } else {
                    let lastUnit = localRemoteUnits.last!
                    let lastOffset = lastUnit.range.upperBound
                    if unitRange.lowerBound > lastOffset {
                        localRemoteUnits.append(VideoCacheUnit(with: .Remote, range: lastOffset..<unitRange.lowerBound))
                    }
                    localRemoteUnits.append(units[i])
                }

                if i == units.count-1 {
                    let localEndOffset = unitRange.upperBound
                    if upperBound > localEndOffset {
                        localRemoteUnits.append(VideoCacheUnit(with: .Remote, range: localEndOffset..<upperBound))
                    }
                }
            }
            units = localRemoteUnits
        }
        return units
    }

    // get data through range
    func cachedData(from range: Range<Int>, block: @escaping (_ data: Data?, _ error: VideoCacheWorkerError?) -> ()) {

        guard let readFileHandle = self.readFileHandle else {
            block(nil, VideoCacheWorkerError.FileHandleNil)
            return
        }
        ioQueue.async {
            readFileHandle.seek(toFileOffset: UInt64(range.lowerBound))
            let data = readFileHandle.readData(ofLength: range.count)
            DispatchQueue.main.async {
                block(data, nil)
            }
        }
    }

    private func save() {
        writeFileHandle?.synchronizeFile()
    }

    func setFile() {
        self.writeFileHandle?.truncateFile(atOffset: UInt64(self.internalCacheConfiguration.expectedSize))
        self.writeFileHandle?.synchronizeFile()
    }

}
