//
//  AVPlayerManager.swift
//  Meipu
//
//  Created by XiaoshaQuan on 9/26/16.
//  Copyright © 2016 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import Foundation
import AVFoundation

//protocol PlayerViewModelProtocol {
//    var  sharedVideoView :MPPlayer?{get set}
//    func getSharedVideoView() ->  MPPlayer
//}
//protocol TagsPlayerViewModelProtocol:PlayerViewModelProtocol {
//    func getSharedTagsVideoView() -> TagsVideoView
//}
//protocol SharedTagsPlayerViewModelProtocol: TagsPlayerViewModelProtocol{
//    var originSuperView:MPPlayerViewContainer?{get set}
//}




class MPPlayerManager {
    
    static let sharedInstance = MPPlayerManager()
    
//    var _sharedTagsVideoView: TagsVideoView?
//
//    var limitCellularAlertCount = 2
//    var currentCellularAlertCount = 0
//    var customSeletedNeedShowCellularAlert = true
//    var canAutoPlayWhenScrollEnd:Bool{
//        return MTNetworkReachabilityManager.shared().networkReachabilityStatus == MTNetworkReachabilityStatus.reachableViaWiFi
//    }
//    var canAutoPlayWhenAppear:Bool{
//        return MTNetworkReachabilityManager.shared().networkReachabilityStatus == MTNetworkReachabilityStatus.reachableViaWiFi
//    }
//    var needShowCellularAlert:Bool{
//        return customSeletedNeedShowCellularAlert && MTNetworkReachabilityManager.shared().networkReachabilityStatus != MTNetworkReachabilityStatus.reachableViaWiFi && MTNetworkReachabilityManager.shared().isReachable
//    }
    
    func showCellularAlert(_ confirmAction:@escaping () -> Void){
//        if currentCellularAlertCount >= limitCellularAlertCount{
//            MeipuCore.sharedInstance.windowInterface?.alert("正在使用蜂窝移动网络，继续使用可能产生流量费用", confirmTitle: "继续播放", confirmAction: { () in
//                confirmAction()
//                }, cancelTitle: "不再提醒", cancelAction: { () in
//                    self.customSeletedNeedShowCellularAlert = false
//                }, otherTitle: "取消", otherAction: { () in
//            })
//        }
//        else{
//            self.currentCellularAlertCount = self.currentCellularAlertCount + 1
//            MeipuCore.sharedInstance.windowInterface?.alert("正在使用蜂窝移动网络，继续使用可能产生流量费用", confirmTitle:"继续播放", confirmAction: { () in
//                self.currentCellularAlertCount = self.currentCellularAlertCount + 1
//                confirmAction()
//                }, cancelTitle: "取消", cancelAction: { () in
//            })
//        }
    }
    
//    func getSharedTagsVideoView() -> TagsVideoView {
//
//        if _sharedTagsVideoView  == nil{
//            _sharedTagsVideoView = TagsVideoView(frame: CGRect.zero, supportCache: true)
//        }
//        return _sharedTagsVideoView!
//    }

}


