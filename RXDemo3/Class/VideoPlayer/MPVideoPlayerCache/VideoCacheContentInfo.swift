//
//  MPVPContentInfo.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/8/22.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import ObjectMapper

class VideoCacheContentInfo: NSObject, NSCoding {
    var contentType: String
    var isByteRangeAccessSupported: Bool
    var contentLength: Int64
    var downloadContentLength: Int64 = 0

    override init() {
        contentType = ""
        isByteRangeAccessSupported = true
        contentLength = 0
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(contentType, forKey: "MPVPContentInfoContentType")
        aCoder.encode(contentLength, forKey: "MPVPContentInfoContentLength")
        aCoder.encode(isByteRangeAccessSupported, forKey: "MPVPContentInfoIsByte")
    }

    required init?(coder aDecoder: NSCoder) {
        if let contentType = aDecoder.decodeObject(forKey: "MPVPContentInfoContentType") as? String {
            self.contentType = contentType
        } else {
            contentType = ""
        }
        contentLength = aDecoder.decodeInt64(forKey: "MPVPContentInfoContentLength")
        isByteRangeAccessSupported = aDecoder.decodeBool(forKey: "MPVPContentInfoIsByte")
    }
}
