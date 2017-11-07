//
//  RefreshFooter.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/16.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import MJRefresh
import YYKit


class RefreshBackFooter : MJRefreshBackFooter {
    // 控件的高度
    var footerHeight : CGFloat = 50
    var noMoreDataHeight : CGFloat = 120
    // 加载动画
    var loadingImageView : UIImageView = UIImageView()
    var loadingImageArray : Array<UIImage> = []
    
    // nomoredata 动画
    var noMoreDataImageView : UIImageView = UIImageView()
    var noMoreDataLabel : UILabel = UILabel()
    
    var noMoreDataImage: UIImage? = UIImage(named: "refresh_footer_no_more_data")
    var noMoreDataText: NSAttributedString = {
        let attributedString =  NSMutableAttributedString(string: "别拉了，到底啦...")
        attributedString.setFont(UIFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: attributedString.length))
        attributedString.setColor(UIColor.mpBEBEBEColor(), range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }()
    
    // MARK - 初始化配置
    override func prepare() {
        super.prepare()
        
        // 设置控件高度
        self.mj_h = footerHeight
        
        // 添加加载动画
        let loadingImageArray : Array<UIImage> = [
            UIImage(named:"refresh_footer_0")!,
            UIImage(named:"refresh_footer_1")!,
            UIImage(named:"refresh_footer_2")!,
            UIImage(named:"refresh_footer_3")!,
            UIImage(named:"refresh_footer_4")!,
            UIImage(named:"refresh_footer_5")!,
            UIImage(named:"refresh_footer_6")!,
            UIImage(named:"refresh_footer_7")!,
            UIImage(named:"refresh_footer_8")!
        ]
        loadingImageView.image = UIImage(named: "refresh_footer_8")
        loadingImageView.animationImages = loadingImageArray
        loadingImageView.animationDuration = 0.9
        loadingImageView.animationRepeatCount = 0
        self.addSubview(loadingImageView)
        
        // 添加 nomoredata 动画
        noMoreDataImageView.image = noMoreDataImage
        noMoreDataImageView.isHidden = true
        self.addSubview(noMoreDataImageView)
        
        noMoreDataLabel.attributedText = noMoreDataText
        noMoreDataLabel.numberOfLines = 0
        noMoreDataLabel.sizeToFit()
        noMoreDataLabel.isHidden = true
        self.addSubview(noMoreDataLabel)
    }
    
    // MARK - 设置子控件的位置和尺寸
    override func placeSubviews() {
        super.placeSubviews()
        
        // 加载动画布局
        loadingImageView.frame = CGRect(x: (self.mj_w - 17) * 0.5, y: 20, width: 17, height: 17)
        
        // nomoredata 动画布局
        
        noMoreDataImageView.frame = CGRect((self.width - 71.0)/2.0, 45, 71, 48)
        noMoreDataLabel.frame = CGRect(x: (self.width - noMoreDataLabel.width)/2.0, y: 103, width: noMoreDataLabel.width, height: noMoreDataLabel.height)
        
    }
    
    // MARK - 监听控件的刷新状态
    override var state: MJRefreshState {
        set {
            if self.state == newValue {
                return
            }
            
            super.state = newValue
            
            switch state {
            case .idle:
                self.mj_h = footerHeight
                self.loadingImageView.isHidden = false
                self.noMoreDataImageView.isHidden = true
                self.noMoreDataLabel.isHidden = true
                self.loadingImageView.stopAnimating()
                break
            case .refreshing:
                self.mj_h = footerHeight
                self.loadingImageView.isHidden = false
                self.loadingImageView.startAnimating()
                self.noMoreDataImageView.isHidden = true
                self.noMoreDataLabel.isHidden = true
                break
                
            case .noMoreData:
                self.mj_h = noMoreDataHeight
                self.loadingImageView.stopAnimating()
                self.loadingImageView.isHidden = true
                self.noMoreDataImageView.isHidden = false
                self.noMoreDataLabel.isHidden = false
                break
                
            default:
                break
            }
        }
        get {
            return super.state
        }
    }
}


class RefreshAutoFooter : MJRefreshAutoFooter {
    var triggerAutomaticallyRefreshDistance: CGFloat = 300
    // 控件的高度
    var footerHeight : CGFloat = 50
    var noMoreDataHeight : CGFloat = 120
    // 加载动画
    var loadingImageView : UIImageView = UIImageView()
    var loadingImageArray : Array<UIImage> = []
    
    // nomoredata 动画
    var noMoreDataImageView : UIImageView = UIImageView()
    var noMoreDataLabel : UILabel = UILabel()
    
    var noMoreDataText: NSAttributedString = {
        let attributedString =  NSMutableAttributedString(string: "别拉了，到底啦...")
        attributedString.setFont(UIFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: attributedString.length))
        attributedString.setColor(UIColor.mpBEBEBEColor(), range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }()
    
    // MARK - 初始化配置
    override func prepare() {
        super.prepare()
        
        // 设置控件高度
        self.mj_h = footerHeight
        
        // 添加加载动画
        let loadingImageArray : Array<UIImage> = [
            UIImage(named:"refresh_footer_0")!,
            UIImage(named:"refresh_footer_1")!,
            UIImage(named:"refresh_footer_2")!,
            UIImage(named:"refresh_footer_3")!,
            UIImage(named:"refresh_footer_4")!,
            UIImage(named:"refresh_footer_5")!,
            UIImage(named:"refresh_footer_6")!,
            UIImage(named:"refresh_footer_7")!,
            UIImage(named:"refresh_footer_8")!
        ]
        loadingImageView.image = UIImage(named: "refresh_footer_8")
        loadingImageView.animationImages = loadingImageArray
        loadingImageView.animationDuration = 0.9
        loadingImageView.animationRepeatCount = 0
        self.addSubview(loadingImageView)
        
        // 添加 nomoredata 动画
        noMoreDataImageView.image = UIImage(named: "refresh_footer_no_more_data")
        noMoreDataImageView.isHidden = true
        self.addSubview(noMoreDataImageView)
        
        noMoreDataLabel.attributedText = noMoreDataText
        noMoreDataLabel.isHidden = true
        noMoreDataLabel.sizeToFit()
        self.addSubview(noMoreDataLabel)
    }
    
    // MARK - 设置子控件的位置和尺寸
    override func placeSubviews() {
        super.placeSubviews()
        
        // 加载动画布局
        loadingImageView.frame = CGRect(x: (self.mj_w - 17) * 0.5, y: 20, width: 17, height: 17)
        
        // nomoredata 动画布局
        
        noMoreDataImageView.frame = CGRect((self.width - 71.0)/2.0, 45, 71, 48)
        noMoreDataLabel.frame = CGRect(x: (self.width - noMoreDataLabel.width)/2.0, y: 103, width: noMoreDataLabel.width, height: noMoreDataLabel.height)
        
    }
    
    // MARK - 监听控件的刷新状态
    override var state: MJRefreshState {
        set {
            if self.state == newValue {
                return
            }
            
            super.state = newValue
            
            switch state {
            case .idle:
                self.mj_h = footerHeight
                self.loadingImageView.isHidden = false
                self.noMoreDataImageView.isHidden = true
                self.noMoreDataLabel.isHidden = true
                self.loadingImageView.stopAnimating()
                break
            case .refreshing:
                self.mj_h = footerHeight
                self.loadingImageView.isHidden = false
                self.loadingImageView.startAnimating()
                self.noMoreDataImageView.isHidden = true
                self.noMoreDataLabel.isHidden = true
                break
                
            case .noMoreData:
                self.mj_h = noMoreDataHeight
                self.loadingImageView.stopAnimating()
                self.loadingImageView.isHidden = true
                self.noMoreDataImageView.isHidden = false
                self.noMoreDataLabel.isHidden = false
                break
                
            default:
                break
            }
        }
        get {
            return super.state
        }
    }
    
    override func scrollViewContentSizeDidChange(_ change: [AnyHashable : Any]!) {
        super.scrollViewContentSizeDidChange(change)
        
        let contentHeight = self.scrollView.mj_contentH + self.ignoredScrollViewContentInsetBottom;
        // 表格的高度
        let scrollHeight = self.scrollView.mj_h - self.scrollViewOriginalInset.top - self.scrollViewOriginalInset.bottom + self.ignoredScrollViewContentInsetBottom;
        // 设置位置和尺寸
        self.mj_y = max(contentHeight, scrollHeight);
    }
    
    
    override func scrollViewContentOffsetDidChange(_ change: [AnyHashable : Any]!) {
        guard let scrollView = scrollView else { return }
        
        if (self.state != .idle || !self.isAutomaticallyRefresh || self.mj_y == 0) {
            return
        }
        if scrollView.mj_insetT + scrollView.mj_contentH > scrollView.mj_h { // 内容超过一个屏幕
            // 这里的_scrollView.mj_contentH替换掉self.mj_y更为合理
            if (scrollView.mj_offsetY >= scrollView.mj_contentH - scrollView.mj_h - triggerAutomaticallyRefreshDistance + scrollView.mj_insetB - self.mj_h) {
                // 防止手松开时连续调用
                let old = (change["old"] as? NSNumber)?.cgPointValue
                let new = (change["new"] as? NSNumber)?.cgPointValue
                if let old = old, let new = new, new.y <= old.y {
                    return
                }
                // 当底部刷新控件完全出现时，才刷新
                beginRefreshing()
            }
        }
    }
}
