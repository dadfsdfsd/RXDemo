//
//  MPVideoCachePath.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/3.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import ObjectMapper
import CommonCrypto

extension Range: StaticMappable {

    public static func objectForMapping(map: Map) -> BaseMappable? {
        if let lowerBound: Bound = map["lowerBound"].value(),
           let upperBound: Bound = map["upperBound"].value()  {
            return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
        }
        return nil
    }

    public func mapping(map: Map) {
        lowerBound >>> map["lowerBound"]
        upperBound >>> map["upperBound"]
    }
}


class VideoCacheConfiguration: NSObject, NSCoding {
    // cache path
    fileprivate let MPVideoCacheForTemporaryFile = "/VideoCacheTemporaryFile"

    // datarequest fill info
    var contentInfo: VideoCacheContentInfo = VideoCacheContentInfo()

    var filePath: String = ""
    var fileName: String = ""

    // record cached range
    var fragments: [Range<Int>] = []

    var url: URL?

    var expectedSize: Int64 = 0
    var receivedSize: Int64 = 0
    
    override init() {
        super.init()
    }

    //MARK: - NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fileName, forKey: "MPVPCFGFileName")
        aCoder.encode(fragments.toJSON(), forKey: "MPVPCFGFragments")
        aCoder.encode(contentInfo, forKey: "MPVPCFGContentInfo")
        aCoder.encode(url, forKey: "MPVPCFGURL")
    }

    required init?(coder aDecoder: NSCoder) {
        if let fileName = aDecoder.decodeObject(forKey: "MPVPCFGFileName") as? String {
            self.fileName = fileName
        } else {
            fileName = ""
        }
        if let fragmentsDics = aDecoder.decodeObject(forKey: "MPVPCFGFragments") as? [[String: Any]] {
            fragments = Mapper<Range<Int>>().mapArray(JSONArray: fragmentsDics)
        } else {
            fragments = []
        }
        if let contentInfo = aDecoder.decodeObject(forKey: "MPVPCFGContentInfo") as? VideoCacheContentInfo {
            self.contentInfo = contentInfo
        } else {
            contentInfo = VideoCacheContentInfo()
        }
        if let url = aDecoder.decodeObject(forKey: "MPVPCFGURL") as? URL {
            self.url = url
        } else {
            url = nil
        }
        super.init()
    }

    static func configuration(with filePath: String) -> VideoCacheConfiguration {
        let path = VideoCacheConfiguration.configurationFilePath(filePath)

        guard let configuration = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? VideoCacheConfiguration else {
            let configuration = VideoCacheConfiguration()
            configuration.fileName = path.lastPathComponent
            configuration.filePath = path
            return configuration
        }

        configuration.filePath = path
        return configuration
    }

    static func configurationFilePath(_ filePath: String) -> String {
        guard let path = (filePath as NSString).appendingPathExtension("mt_cfg") else { return "" }
        return path
    }

    var progress: Float {
        if expectedSize == 0 {
            return 0
        }
        return Float(receivedSize)/Float(expectedSize)
    }

    func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: self.filePath)
    }

    func add(cacheFragment fragment: Range<Int>) {

        if fragment.lowerBound == Int.max || fragment.count == 0 { return }

        let count = fragments.count
        if count == 0 {
            fragments.append(fragment)
        } else {

            var indexSet = IndexSet()

            for i in 0..<fragments.count {
                if fragment.upperBound < fragments[i].lowerBound {
                    if indexSet.count == 0 {
                        indexSet.insert(i)
                        break
                    }
                }
                else if fragment.lowerBound <= fragments[i].upperBound && fragments[i].lowerBound <= fragment.upperBound {
                    indexSet.insert(i)
                }
                else if fragment.lowerBound >= fragments[i].upperBound {
                    if i == count-1 {
                        indexSet.insert(i)
                    }
                }
            }

            if indexSet.count > 1 {
                let firstRange = fragments[indexSet.first!]
                let lastRange = fragments[indexSet.last!]
                let lowerBound = min(firstRange.lowerBound, lastRange.lowerBound)
                let upperBound = max(lastRange.upperBound, fragment.upperBound)
                let combineRange: Range = lowerBound..<upperBound
                let tempArr: [Int] = indexSet.reversed()
                _ = tempArr.map {
                    fragments.remove(at: $0)
                }
                fragments.insert(combineRange, at: indexSet.first!)
            }
            else if indexSet.count == 1 {
                let firstRange = fragments[indexSet.first!]

                let expandFirstRange: Range = firstRange.lowerBound..<firstRange.upperBound+1
                let expandFragmentRange: Range = fragment.lowerBound..<fragment.upperBound+1
                let intersectionRange = expandFirstRange.clamped(to: expandFragmentRange)

                if intersectionRange.count > 0 {
                    let lowerBound = min(firstRange.lowerBound, fragment.lowerBound)
                    let upperBound = max(firstRange.upperBound, fragment.upperBound)
                    let combineRange: Range = lowerBound..<upperBound
                    fragments.remove(at: indexSet.first!)
                    fragments.insert(combineRange, at: indexSet.first!)
                }
                else {
                    if firstRange.lowerBound > fragment.lowerBound {
                        fragments.insert(fragment, at: indexSet.last!)
                    } else {
                        fragments.insert(fragment, at: indexSet.last!+1)
                    }
                }
            }
        }

        var cacheLength: Int64 = 0
        for i in 0..<fragments.count {
            cacheLength = cacheLength+Int64(fragments[i].count)
        }
        receivedSize = cacheLength
        debug_print("received: \(cacheLength)")
    }

}


//MARK: - Cache Path
extension VideoCacheConfiguration {

    /// Get the local video cache path for all temporary video file.
    ///
    /// - Returns: The temporary file path.
    static func videoCachePathForAllTemporaryFile() -> String {
        return VideoCacheConfiguration().getFilePath(appendString: VideoCacheConfiguration().MPVideoCacheForTemporaryFile)
    }

    /// Get the local video cache path for temporary video file.
    ///
    /// - Parameter key: The unique flag for the given url in this framework.
    /// - Returns: The temporary file path.
    static func videoCacheTemporaryPath(key: String) -> String {
        var path = videoCachePathForAllTemporaryFile()
        if path.length != 0 {
            let fileManager = FileManager.default
            path = path.stringByAppendingPathComponent(key.md5)
            if !fileManager.fileExists(atPath: path) {
                fileManager.createFile(atPath: path, contents: nil, attributes: nil)
            }
        }
        return path
    }

    fileprivate func getFilePath(appendString str: String) -> String {
        let fileManager = FileManager.default
        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last?.appending(str) else { return "" }

        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                debug_print(error)
                return ""
            }
        }
        return path
    }

    //MARK: - File Name

    // use md5
    func cacheFileName(key: String) -> String{
        let str = key.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(key.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)

        CC_MD5(str!, strLen, result)

        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate(capacity: digestLen)

        return hash as String
    }
}
