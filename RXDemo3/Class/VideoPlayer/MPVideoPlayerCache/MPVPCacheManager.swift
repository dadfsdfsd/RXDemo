//
//  MPVideoCache.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/2.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import UIKit

class MPVPCachedFileInformation: NSObject, NSCoding {
    var url: URL?
    var filePath: String
    var fileSize: Int64
    var lastRecentUseTime: Date

    init(url: URL? = nil, filePath: String = "", fileSize: Int64 = 0, time: Date = Date()) {
        self.url = url
        self.filePath = filePath
        self.fileSize = fileSize
        self.lastRecentUseTime = time
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: "MPVPCachedFileUrl")
        aCoder.encode(filePath, forKey: "MPVPCachedFilePath")
        aCoder.encode(fileSize, forKey: "MPVPCachedFileSize")
        aCoder.encode(lastRecentUseTime, forKey: "MPVPCachedFileTime")
    }

    required init?(coder aDecoder: NSCoder) {
        if let url = aDecoder.decodeObject(forKey: "MPVPCachedFileUrl") as? URL {
            self.url = url
        } else {
            url = nil
        }
        if let filePath = aDecoder.decodeObject(forKey: "MPVPCachedFilePath") as? String {
            self.filePath = filePath
        } else {
            filePath = ""
        }
        fileSize = aDecoder.decodeInt64(forKey: "MPVPCachedFileSize")
        if let time = aDecoder.decodeObject(forKey: "MPVPCachedFileTime") as? Date {
            lastRecentUseTime = time
        } else {
            lastRecentUseTime = Date()
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? MPVPCachedFileInformation else { return false }

        if filePath == rhs.filePath {
            return true
        }
        return false
    }
}

class MPVPCacheManager: NSObject {

    lazy fileprivate var tempFileEntrysPath = MPVPCacheConfiguration.videoCachePathForAllTemporaryFile().stringByAppendingPathComponent("FileEntrys")
    lazy fileprivate var fullFileEntrysPath = MPVPCacheConfiguration.videoCachePathForAllFullFile().stringByAppendingPathComponent("FileEntrys")

    lazy fileprivate var fileManager = FileManager.default

    fileprivate var lruTime: TimeInterval = 60 * 60 * 24 * 5 // 5days
    fileprivate var maxCachedNum = 20
    fileprivate var maxCachedSize: Int64 = 1000 * 1000 * 1000 // 1G
    fileprivate var _lock = MutexLock(.Recursive)

    // size/1000/1000 = mb
    var cachedFileSize: Int64 = 0

    var deviceFreeSize: Int64 = 0

    var currentCachedNum = 0 {
        willSet {
            if newValue >= maxCachedNum {
                removeBeforeEntry()
                currentCachedNum = maxCachedNum - 1
            }
        }
    }

    var cachedTempFileEntrys: [MPVPCachedFileInformation] = []

    var cachedFullFileEntrys: [MPVPCachedFileInformation] = []

    var isAutoClearOldCaches = true

    //MARK: - Singleton
    static let sharedInstance = MPVPCacheManager()

    override init() {
        super.init()
        readFileEntrys()
        currentCachedNum = cachedTempFileEntrys.count + cachedFullFileEntrys.count
        deviceFreeSize = getDiskFreeSize()
        if isAutoClearOldCaches {
            deleteOldFiles()
        }
    }

    deinit {
        saveFileEntrys()
    }

    //MARK: - FileEntry Manage
    func addTempFileEntry(_ entry: MPVPCachedFileInformation) {
        _lock.run {
            guard let index = cachedTempFileEntrys.index(of: entry) else {
                currentCachedNum += 1
                cachedTempFileEntrys.append(entry)
                deviceFreeSize -= entry.fileSize
                cachedFileSize += entry.fileSize
                judegeFileSize()
                return
            }
            let tempEntry = cachedTempFileEntrys[index]
            deviceFreeSize = deviceFreeSize+tempEntry.fileSize-entry.fileSize
            cachedFileSize = cachedFileSize-tempEntry.fileSize+entry.fileSize
            cachedTempFileEntrys.remove(at: index)
            cachedTempFileEntrys.append(entry)
            judegeFileSize()
        }
    }

    func addFullFileEntry(_ entry: MPVPCachedFileInformation) {
        _lock.run {
            guard let index = cachedFullFileEntrys.index(of: entry) else {
                currentCachedNum += 1
                cachedFullFileEntrys.append(entry)
                deviceFreeSize -= entry.fileSize
                judegeFileSize()
                return
            }
            let tempEntry = cachedFullFileEntrys[index]
            deviceFreeSize = deviceFreeSize+tempEntry.fileSize-entry.fileSize
            cachedFullFileEntrys.remove(at: index)
            cachedFullFileEntrys.append(entry)
            judegeFileSize()
        }
    }

    func moveToFullFile(entry: MPVPCachedFileInformation) {
        guard let url = entry.url else { return }
        do {
            let fullPath = MPVPCacheConfiguration.videoCacheFullPath(key: url.absoluteString)
            try fileManager.moveItem(atPath: entry.filePath, toPath: fullPath)
            guard let index = cachedTempFileEntrys.index(of: entry) else { return }
            cachedTempFileEntrys.remove(at: index)
            entry.lastRecentUseTime = Date()
            cachedFullFileEntrys.append(entry)
            MPVPCacheConfiguration.removeConfiguartion(with: url)
        } catch {
            print(error)
        }
    }

    fileprivate func judegeFileSize() {
        if cachedFileSize > maxCachedSize {
            removeBeforeEntry()
            judegeFileSize()
        }
    }

    fileprivate func removeBeforeEntry() {
        _lock.run {
            var entry = MPVPCachedFileInformation()
            if cachedTempFileEntrys.count != 0 {
                entry = cachedTempFileEntrys[0]
                cachedTempFileEntrys.remove(at: 0)
            } else if cachedFullFileEntrys.count != 0 {
                entry = cachedFullFileEntrys[0]
                cachedFullFileEntrys.remove(at: 0)
            }
            guard let url = entry.url else { return }
            do {
                try fileManager.removeItem(atPath: entry.filePath)
                MPVPCacheConfiguration.removeConfiguartion(with: url)
                cachedFileSize -= entry.fileSize
                deviceFreeSize += entry.fileSize
            } catch {
                print(error)
            }
        }
    }

    //MARK: - Archive/Unarchive CacheFile Information
    func saveFileEntrys() {
        saveTempFileEntrys()
        saveFullFileEntrys()
    }

    fileprivate func readFileEntrys() {
        readTempFileEntrys()
        readFullFileEntrys()
    }

    fileprivate func saveTempFileEntrys() {
        if !NSKeyedArchiver.archiveRootObject(cachedTempFileEntrys, toFile: tempFileEntrysPath) {
            print("VideoCacheTempFileEntrysStoredError")
        }
    }

    fileprivate func saveFullFileEntrys() {
        if cachedFullFileEntrys.count > 0 {
            if !NSKeyedArchiver.archiveRootObject(cachedFullFileEntrys, toFile: fullFileEntrysPath) {
                print("VideoCacheFullFileEntrysStoredError")
            }
        }
    }

    fileprivate func readTempFileEntrys() {
        guard let fileEntrys = NSKeyedUnarchiver.unarchiveObject(withFile: tempFileEntrysPath) as? [MPVPCachedFileInformation] else {
            cachedTempFileEntrys = []
            return
        }
        cachedTempFileEntrys = fileEntrys
    }

    fileprivate func readFullFileEntrys() {
        guard let fileEntrys = NSKeyedUnarchiver.unarchiveObject(withFile: fullFileEntrysPath) as? [MPVPCachedFileInformation] else {
            cachedFullFileEntrys = []
            return
        }
        cachedFullFileEntrys = fileEntrys
    }

    //MARK: - Query and Retrieve Options
    func queryCache(key: URL, doneBlock: ((_ videoPath: String?) -> ())?) {
        let filePath = MPVPCacheConfiguration.videoCacheFullPath(key: key.absoluteString)
        let exists = cachedFullFileEntrys.contains(MPVPCachedFileInformation(url: key, filePath: filePath, fileSize: 0, time: Date()))
        if exists {
            doneBlock?(filePath)
        } else {
            doneBlock?(nil)
        }
    }


    //MARK: - Clear Cache Events

    /// Remove the video data from disk cache asynchronously
    ///
    /// - Parameter key: The unique video cache key.
    func removeFullCache(key: String) {
        let path = MPVPCacheConfiguration.videoCacheFullPath(key: key)

        var entry = MPVPCachedFileInformation(filePath: path, fileSize: 0, time: Date())

        if cachedFullFileEntrys.contains(entry) {
            do {
                try fileManager.removeItem(atPath: path)

                guard let index = cachedFullFileEntrys.index(of: entry) else { return }

                entry = cachedFullFileEntrys[index]
                cachedFullFileEntrys.remove(at: index)
                deviceFreeSize += entry.fileSize
            } catch {
                print(error)
            }
        }
    }


    /// Clear the temporary cache video for given key.
    ///
    /// - Parameter key: The unique flag for the given url in this framework.
    func removeTempCache(key: String) {
        var path = MPVPCacheConfiguration.videoCachePathForAllTemporaryFile()
        path = path.stringByAppendingPathComponent(key.md5)

        var entry = MPVPCachedFileInformation(filePath: path, fileSize: 0, time: Date())

        if cachedTempFileEntrys.contains(entry) {
            do {
                try fileManager.removeItem(atPath: path)

                guard let index = cachedTempFileEntrys.index(of: entry) else { return }
                entry = cachedTempFileEntrys[index]
                cachedTempFileEntrys.remove(at: index)
                guard let url = entry.url else { return }
                MPVPCacheConfiguration.removeConfiguartion(with: url)
                deviceFreeSize += entry.fileSize
            } catch {
                print(error)
            }
        }
    }


    /// Async remove all expired cached video from disk.
    func deleteOldFiles() {
        for entry in cachedTempFileEntrys {
            if (entry.lastRecentUseTime.timeIntervalSince1970 - Date().timeIntervalSince1970) > lruTime {
                do {
                    try fileManager.removeItem(atPath: entry.filePath)
                    deviceFreeSize += entry.fileSize
                    guard let url = entry.url else { return }
                    MPVPCacheConfiguration.removeConfiguartion(with: url)
                } catch {
                    print(error)
                }
            } else {
                break
            }
        }

        for entry in cachedFullFileEntrys {
            if (entry.lastRecentUseTime.timeIntervalSince1970 - Date().timeIntervalSince1970) > lruTime {
                do {
                    try fileManager.removeItem(atPath: entry.filePath)
                    deviceFreeSize += entry.fileSize
                } catch {
                    print(error)
                }
            } else {
                break
            }
        }
    }

    /// Async delete all temporary cached videos.
    func deleteAllTempCache(completion: (() -> ())?) {

        do {
            try self.fileManager.removeItem(atPath: MPVPCacheConfiguration.videoCachePathForAllTemporaryFile())
            for entry in cachedTempFileEntrys {
                deviceFreeSize += entry.fileSize
            }
            currentCachedNum -= cachedTempFileEntrys.count
            currentCachedNum = currentCachedNum<0 ? 0 : currentCachedNum
            cachedTempFileEntrys.removeAll()
        } catch let error as NSError {
            print(error)
        }
        dispatch_main_async_safe {
            guard let completion = completion else { return }
            completion()
        }
    }

    func deleteAllFullCache(completion: (() -> ())?) {

        do {
            try self.fileManager.removeItem(atPath: MPVPCacheConfiguration.videoCachePathForAllFullFile())
            for entry in cachedFullFileEntrys {
                deviceFreeSize += entry.fileSize
            }
            currentCachedNum -= cachedFullFileEntrys.count
            currentCachedNum = currentCachedNum<0 ? 0 : currentCachedNum
            cachedFullFileEntrys.removeAll()
        } catch let error as NSError {
            print(error)
        }
        dispatch_main_async_safe {
            guard let completion = completion else { return }
            completion()
        }
    }

    /// Async clear all disk cached videos.
    func clearDisk() {
        
        deleteAllTempCache(completion: nil)
        deleteAllFullCache(completion: nil)
    }

    //MARK: - Cache Info

    static func isEnoughSizeToCache(cacheSize: Int64) -> Bool {
        if cacheSize > MPVPCacheManager.sharedInstance.deviceFreeSize {
            return false
        }
        return true
    }

    fileprivate func getDiskFreeSize() -> Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
//            let totalSize = (systemAttributes[.systemSize] as? NSNumber)?.int64Value
            let freeSize = (systemAttributes[.systemFreeSize] as? NSNumber)?.int64Value else {
                return 0
        }
        return freeSize
    }
}
