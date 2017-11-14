//
//  PlayerFinishView.swift
//  RXDemo3
//
//  Created by fan yang on 2017/11/9.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation
import UIKit
import SnapKit


protocol PlayerFinishedViewDelegate {
    
    func playFromBeginning()
    
}


class PlayerFinishedView: UIView {
    
    weak var delegate: AnyObject?
    
    var replayButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.red
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(replayButton)
        replayButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(50)
        }
        
        replayButton.addTarget(self, action: #selector(onReplay) , for: UIControlEvents.touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc dynamic func onReplay() {
        guard let delegate = delegate as? PlayerFinishedViewDelegate else { return }
        delegate.playFromBeginning()
    }
}



protocol PlayerFailedViewDelegate {
    
    func retryPlay()
    
}


class PlayerFailedView: UIView {
    
    weak var delegate: AnyObject?
    
    lazy private(set) var retryButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: 30))
        button.layer.borderColor = UIColor(red: 1, green: 0, blue: 76/255, alpha: 1).cgColor
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 0.5
        button.setTitle("点击重试", for: .normal)
        button.setTitleColor(UIColor(red: 1, green: 0, blue: 76/255, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(retryPlay), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return button
    }()
    
    lazy private(set) var loadFailedLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.mpLightFontOfSize(15)
        label.text = "视频加载失败"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(retryButton)
        addSubview(loadFailedLabel)
        
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loadFailedLabel.height = 30
        loadFailedLabel.width  = 120
        loadFailedLabel.centerY = self.height/2 - 20
        loadFailedLabel.centerX = self.width/2
        
        retryButton.height = 30
        retryButton.width  = 120
        retryButton.top = loadFailedLabel.bottom + 17
        retryButton.centerX = self.width/2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc dynamic func retryPlay() {
        if let delegate = delegate as? PlayerFailedViewDelegate {
            delegate.retryPlay()
        }
    }
    
}
