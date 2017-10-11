//
//  MPCommonPlayer.swift
//  Meipu
//
//  Created by fan yang on 2017/4/10.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import UIKit

class MPCommonPlayer: MPPlayer {
    
    var contentId: IDType = 0
    
    var isLiked : Bool {
        didSet {
            buttonLike.isSelected = isLiked
            labelLike.text = isLiked ? "已点赞" : "点个赞"
        }
    }
    
    fileprivate let buttonLike = UIButton()
    fileprivate let labelLike = UILabel()
    fileprivate let buttonReplay = UIButton()
    fileprivate let labelReplay = UILabel()
    
    override func leftOfMuteButton() -> CGFloat {
        return 10
    }
    
    override init(frame: CGRect, supportCache: Bool) {
        isLiked = false
        super.init(frame: frame, supportCache: supportCache)
        buttonLike.setImage(UIImage.init(named: "icon_video_liked"), for: .selected)
        buttonLike.setImage(UIImage.init(named: "icon_video_unliked"), for: UIControlState())
        buttonLike.addTarget(self, action: #selector(onLike), for: .touchUpInside)
        self.finishView.addSubview(buttonLike)
        
        labelLike.text = "点个赞"
        labelLike.textColor = UIColor.mpFFFFFFColor()
        labelLike.font = UIFont.mpFontOfSize(11)
        self.finishView.addSubview(labelLike)
        
        buttonLike.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.finishView)
            make.centerX.equalTo(self.finishView).offset(-24.0 - 37.5)
        }
        
        labelLike.snp.makeConstraints { (make) in
            make.top.equalTo(self.buttonLike.snp.bottom).offset(10)
            make.centerX.equalTo(self.buttonLike)
        }
        
        buttonReplay.setImage(UIImage.init(named: "icon_video_replay"), for: .selected)
        buttonReplay.setImage(UIImage.init(named: "icon_video_replay"), for: UIControlState())
        buttonReplay.addTarget(self, action: #selector(onReplay), for: .touchUpInside)
        self.finishView.addSubview(buttonReplay)
        
        labelReplay.text = "重播"
        labelReplay.textColor = UIColor.mpFFFFFFColor()
        labelReplay.font = UIFont.mpFontOfSize(11)
        self.finishView.addSubview(labelReplay)
        self.bringSubview(toFront: self.fullScreenBtn)
        
        buttonReplay.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.finishView)
            make.centerX.equalTo(self.finishView).offset(24.0 + 37.5)
        }
        
        labelReplay.snp.makeConstraints { (make) in
            make.top.equalTo(self.buttonReplay.snp.bottom).offset(10)
            make.centerX.equalTo(self.buttonReplay)
        }
        
        
        
        self.kvoController.observe(self.finishView, keyPath: "hidden", options: []) { [weak self] (observer, observee, change) in
            guard let strongSelf = self else {
                return
            }
            if !strongSelf.finishView.isHidden {
                strongSelf.buttonLike.isHidden = strongSelf.isLiked
                strongSelf.labelLike.isHidden = strongSelf.isLiked
                
                strongSelf.buttonReplay.snp.remakeConstraints { (make) in
                    make.centerY.equalTo(strongSelf.finishView)
                    make.centerX.equalTo(strongSelf.finishView).offset(24.0+37.5)
                }
                
                if strongSelf.isLiked {
                    strongSelf.buttonReplay.snp.remakeConstraints { (make) in
                        make.centerY.equalTo(strongSelf.finishView)
                        make.centerX.equalTo(strongSelf.finishView)
                    }
                } else {
                    strongSelf.buttonReplay.snp.remakeConstraints { (make) in
                        make.centerY.equalTo(strongSelf.finishView)
                        make.centerX.equalTo(strongSelf.finishView).offset(24.0+37.5)
                    }
                }
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    @objc fileprivate func onTapFinishView() {
//        if self.isFullscreen {
//            self.toSmallScreen()
//        }
//    }
    
    @objc fileprivate func onLike() {
        
        if !LoginHelper.hasLoggedIn {
            if self.isFullscreen{
                self.toSmallScreen(animated: false)
            }
        }
        
        LoginHelper.login { (result) in
            
            switch result {
            case .success(_):
                
                guard let model = DataModelCore.sharedInstance.dataModelWithIdentifier(UserContentCenter.identifier) as? UserContentCenter else {
                    return
                }
                
                self.isLiked = !self.isLiked
                
                let context: EditUserContentDataContext = self.isLiked ? .like(self.contentId) : .unLike(self.contentId)
                
                model.editContent(context, completion: { (data, error, taskId) in
                    if let data = data as? Dictionary<String, Any>, let toast = data["toast"] as? String {
                        ToastQueue.sharedInstance.makeToast(toast)
                    }
                })
                
            case .failure(_):
                break
            }
        }
    }
}
