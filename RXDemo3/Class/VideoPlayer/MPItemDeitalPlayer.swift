//
//  MPItemDeitalPlayer.swift
//  Meipu
//
//  Created by fan yang on 2017/4/10.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import UIKit

class MPItemDeitalPlayer : MPPlayer {
    fileprivate let buttonReplay = UIButton()
    var heightWidthRatio:CGFloat = 1.2
    
    override init(frame: CGRect, supportCache: Bool) {
        super.init(frame: frame, supportCache: supportCache)
        buttonReplay.setImage(UIImage.init(named: "icon_play"), for: .selected)
        buttonReplay.setImage(UIImage.init(named: "icon_play"), for: UIControlState())
        buttonReplay.addTarget(self, action: #selector(onReplay), for: .touchUpInside)
        self.finishView.addSubview(buttonReplay)
        
        buttonReplay.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.finishView)
            make.centerX.equalTo(self.finishView)
        }
    }
    
    override func refreshGravity(){
        if self.isFullscreen{
            super.refreshGravity()
        }
        else{
            if self.videoSize.height != 0 && self.videoSize.width != 0 {
                if self.videoSize.height/self.videoSize.width > self.heightWidthRatio{
                    self.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                }
                else{
                    self.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
                }
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func leftOfMuteButton() -> CGFloat {
        return 10
    }
}



