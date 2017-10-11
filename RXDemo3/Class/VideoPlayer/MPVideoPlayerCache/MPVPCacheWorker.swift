//
//  MPVideoPlayerCacheWorker.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/8.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation

enum MPVPCacheWorkerError: Error {
    case FileHandleNil
    case Unknown
}

let kPackageLength = 204800

class MPVPCacheWorker: NSObject {

    fileprivate var readFileHandle: FileHandle? = nil
    fileprivate var writeFileHandle: FileHandle? = nil
    fileprivate var writeBytes = 0
    fileprivate let filePath: String
    fileprivate let url: URL
    fileprivate var writting = true
    fileprivate var startWriteDate: Date? = nil
    fileprivate var ioQueue: DispatchQueue
    var internalCacheConfiguration: MPVPCacheConfiguration = MPVPCacheConfiguration()


    //MARK: - Public
    init(with url: URL, configuration: MPVPCacheConfiguration, _ ioQueue: DispatchQueue) {
        self.ioQueue = ioQueue
        let path = MPVPCacheConfiguration.videoCacheTemporaryPath(key: url.absoluteString)
        self.url = url
        filePath = path
        internalCacheConfiguration = configuration
        let fileURL = URL(fileURLWithPath: path)

        do {
            readFileHandle = try FileHandle(forReadingFrom: fileURL)
            writeFileHandle = try FileHandle(forWritingTo: fileURL)
        } catch {
            print(error)
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
            throw MPVPCacheWorkerError.FileHandleNil
        }
        ioQueue.async {
            writeFileHandle.seek(toFileOffset: UInt64(range.lowerBound))
            writeFileHandle.write(data)

            DispatchQueue.main.async {
                self.writeBytes += data.count

                self.internalCacheConfiguration.add(cacheFragment: range)

                if self.internalCacheConfiguration.expectedSize == self.internalCacheConfiguration.receivedSize {
                    print("receive complete")
                }
                self.save()
            }
        }
    }

    // get cacheUnits(wthere local or remote) from range
    func cacheUnits(from range: Range<Int>) -> [MPVPCacheUnit] {
        var units: [MPVPCacheUnit] = []

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

                    units.append(MPVPCacheUnit(with: .Local, range: offsetLowerBound..<(offsetLowerBound+length)))
                }
            } else if fragmentRange.lowerBound >= upperBound {
                break
            }
        }

        if units.count == 0 {
            units.append(MPVPCacheUnit(with: .Remote, range: range))
        } else {
            var localRemoteUnits: [MPVPCacheUnit] = []
            for i in 0..<units.count {
                let unitRange = units[i].range
                if i == 0 {
                    if range.lowerBound < unitRange.lowerBound {
                        localRemoteUnits.append(MPVPCacheUnit(with: .Remote, range: range.lowerBound..<unitRange.lowerBound))
                    }
                    localRemoteUnits.append(units[i])
                } else {
                    let lastUnit = localRemoteUnits.last!
                    let lastOffset = lastUnit.range.upperBound
                    if unitRange.lowerBound > lastOffset {
                        localRemoteUnits.append(MPVPCacheUnit(with: .Remote, range: lastOffset..<unitRange.lowerBound))
                    }
                    localRemoteUnits.append(units[i])
                }

                if i == units.count-1 {
                    let localEndOffset = unitRange.upperBound
                    if upperBound > localEndOffset {
                        localRemoteUnits.append(MPVPCacheUnit(with: .Remote, range: localEndOffset..<upperBound))
                    }
                }
            }
            units = localRemoteUnits
        }
        return units
    }

    // get data through range
    func cachedData(from range: Range<Int>, block: @escaping (_ data: Data?, _ error: MPVPCacheWorkerError?) -> ()) {

        guard let readFileHandle = self.readFileHandle else {
            block(nil, MPVPCacheWorkerError.FileHandleNil)
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

    func save() {
        writeFileHandle?.synchronizeFile()
        internalCacheConfiguration.save()
    }

    func startWritting() {
        if !writting {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        }
        writting = true
        startWriteDate = Date()
        writeBytes = 0
    }

    func finishWritting() {
        if writting {
            writting = false
            NotificationCenter.default.removeObserver(self)
            guard startWriteDate != nil else { return }
        }
    }

    func setFile() {
        self.writeFileHandle?.truncateFile(atOffset: UInt64(self.internalCacheConfiguration.expectedSize))
        self.writeFileHandle?.synchronizeFile()
    }

    //MARK: - Notification
    @objc func applicationDidEnterBackground(notification: Notification) {
        save()
    }
}
