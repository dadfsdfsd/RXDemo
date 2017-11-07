//
//  QYViewController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/19.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

class QiYuManager: NSObject {
    
    static let shared: QiYuManager = QiYuManager()
    
    @objc dynamic var unreadCount: Int = 0
    
    override init() {
        super.init()
        unreadCount = QYSDK.shared().conversationManager().allUnreadCount()
        QYSDK.shared().conversationManager().setDelegate(self)
    }
    
    
    func register() {
        QYSDK.shared().registerAppId("f95c17adf9d5a5277e1ee683ce71e186", appName: "美图美妆iOS")
    }
    
    func logout() {
        QYSDK.shared().logout {}
    }
}

extension QiYuManager: QYConversationManagerDelegate {
    
    func onUnreadCountChanged(_ count: Int) {
        unreadCount = QYSDK.shared().conversationManager().allUnreadCount()
    }
    
    func onSessionListChanged(_ sessionList: [QYSessionInfo]!) {
        
    }
    
    func onReceiveMessage(_ message: QYMessageInfo!) {
        
    }
}


