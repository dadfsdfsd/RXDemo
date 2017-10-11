//
//  String+.swift
//
//  Created by XiaoshaQuan on 5/8/16.
//

import CommonCrypto

extension String {
    
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    public var md5: String {
        
        let bytes = self.cString(using: String.Encoding.utf8)
        let bytesLength = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let r = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)
        
        CC_MD5(bytes!, bytesLength, r)
        
        let str = NSString(format: "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15])
        
        r.deallocate(capacity: digestLength)
        
        return str as String
    }
    
    public func stringByAppendingPathComponent(_ path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }
    
    public func stringByAppendingUrlComponent(_ component: String) -> String {
        if self.characters.last == "/" {
            return self + component
        }
        else {
            return self + "/\(component)"
        }
    }
    
    public var length: Int {
        return self.characters.count
    }
    
    public subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    public subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    public subscript (r: Range<Int>) -> String {
        let s = self.index(self.startIndex, offsetBy: r.lowerBound)
        let e = self.index(s, offsetBy: r.upperBound - r.lowerBound)
        return String(self[Range(s ..< e)])
    }
    
    public static func randomStringWithLength(_ length: Int) -> String {
        
        let randomString = NSMutableString(capacity: length)
        
        for _ in 0..<length {
            let pos: Int = Int(arc4random_uniform(UInt32(letters.length)))
            randomString.appendFormat("%C", letters.character(at: pos))
        }
        
        return randomString as String
    }
}


private let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

