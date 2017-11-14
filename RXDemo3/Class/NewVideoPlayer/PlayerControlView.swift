//
//  PlayerControlView.swift
//  RXDemo3
//
//  Created by fan yang on 2017/11/9.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation
import UIKit

class PlayerControlView: UIView {
    
    var isPlaying: PlayerControlProperty<Bool> = PlayerControlProperty<Bool>(false)
    
    var isBuffering: PlayerControlProperty<Bool> = PlayerControlProperty<Bool>(false)
    
    var isMute: PlayerControlProperty<Bool> = PlayerControlProperty<Bool>(true)
    
    var isFullScreen: PlayerControlProperty<Bool> = PlayerControlProperty<Bool>(false)
    
    var progress: PlayerControlProperty<Double> = PlayerControlProperty<Double>(0.00)
    
    var maximumDuration: PlayerControlProperty<Float> = PlayerControlProperty<Float>(0.00)
    
    var currentTime: PlayerControlProperty<Float> = PlayerControlProperty<Float>(0.00)
    
    var seekToTime:  PlayerControlProperty<Float> = PlayerControlProperty<Float>(0.00)
    
    var isDragingSlider: Bool = false
    
    var canDrag: Bool = true
    
    private(set) var fullScreenBtn: HittestButton = {
        let button = HittestButton()
        button.hitExpand = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)
        button.showsTouchWhenHighlighted = true
        button.addTarget(self, action: #selector(fullScreenAction(sender:)), for: .touchUpInside)
        button.setImage(UIImage(named: "icon_fullscreen"), for: .normal)
        button.setImage(UIImage(named: "video_quit_fullscreen"), for: .selected)
        return button
    }()
    
    private(set) var bottomView: UIView = {
        let view = UIView()
        return view
    }()
    
    private(set) var loadingView: SimpleLoadingView = {
        let view = SimpleLoadingView(frame: CGRect(x: 0, y: 0, width: 52, height: 52))
        return view
    }()
    
    private(set) var leftTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .left
        label.textColor = .white
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 11)
        return label
    }()
    
    private(set) var rightTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .right
        label.textColor = .white
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 11)
        return label
    }()
    
    private(set) var forwardLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.numberOfLines = 0
        return label
    }()
    
    lazy private(set) var progressSlider: UISlider = {
        let slider = UISlider()
        
        slider.backgroundColor = .clear
        slider.minimumValue = 0.0
        slider.setThumbImage(UIImage(named: "video_dot2"), for: .normal)
        slider.minimumTrackTintColor = UIColor(red: 1, green: 0, blue: 76/255, alpha: 1)
        slider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.2)
        slider.value = 0.0
        slider.addTarget(self, action: #selector(stratDragSlide(slider:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(updateProgress(slider:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return slider
    }()
    
    private(set) var gradientLayer: CAGradientLayer = {
        let colorTop = UIColor(white: 0, alpha: 0)
        let colorBottom = UIColor(white: 0, alpha: 0.2)
        let layer = CAGradientLayer()
        layer.colors = Array(arrayLiteral: colorTop.cgColor, colorBottom.cgColor)
        layer.locations = [0, 1]
        return layer
    }()
    
    private(set) var loadingProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.default)
        progressView.progressTintColor = UIColor(white: 1, alpha: 0.2)
        progressView.trackTintColor = .clear
        progressView.backgroundColor = .clear
        progressView.setProgress(0.0, animated: false)
        return progressView
    }()
    
    private(set) var bottomProgress: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1, green: 0, blue: 76/255, alpha: 1)
        return view
    }()
    
        lazy private(set) var gestureProxyScrollView: GestureProxyScrollView = {
            let scrollView = GestureProxyScrollView()
            scrollView.frame = self.bounds
            scrollView.gesEnabled = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.isUserInteractionEnabled = false
            scrollView.bounces = false
            self.addGestureRecognizer(scrollView.panGestureRecognizer)
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollGes(ges:)))
            return scrollView
        }()
    
    lazy private(set) var backButton: HittestButton = {
        let button = HittestButton()
        button.hitExpand = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.setImage(UIImage(named: "video_back"), for: .normal)
        button.addTarget(self, action: #selector(onTapBackBtn(sender:)), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
    
    lazy private(set) var muteButton: HittestButton = {
        let button = HittestButton()
        button.hitExpand = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "icon_mute"), for: .normal)
        button.setImage(UIImage(named: "icon_no_mute"), for: .selected)
        button.addTarget(self, action: #selector(onMute(sender:)), for: .touchUpInside)
        return button
    }()
    
    
    lazy private(set) var playButton: HittestButton = {
        let button = HittestButton()
        button.showsTouchWhenHighlighted = true
        button.addTarget(self, action: #selector(playOrPause(sender:)), for: .touchUpInside)
        button.setImage(UIImage(named: "icon_video_pause_new"), for: .normal)
        button.setImage(UIImage(named: "icon_video_play_new"), for: .selected)
        return button
    }()
    
    lazy private var dateFormatter = DateFormatter()
    
    internal func convertTime(second: CGFloat) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(second))
        if second/3600 >= 1 {
            dateFormatter.dateFormat = "HH:mm:ss"
        } else {
            dateFormatter.dateFormat = "mm:ss"
        }
        let newTime = dateFormatter.string(from: d)
        return newTime
    }
    
    var isShowControlView: DelayedProperty<Bool>?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isShowControlView = DelayedProperty<Bool>(true, changeHandlerBlock: { (value) in
            UIView.animate(withDuration: 0.3, animations: {
                self.bottomView.alpha = value ? 1 : 0
                self.playButton.alpha = self.isPlaying.value ? (value ? 1 : 0) : 1
            }, completion: nil)
        })
        isShowControlView?.setValue(false, withDelay: 2)
        
        setupSubviews()
        setupProperty()
        setupGesture()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        addSubview(gestureProxyScrollView)
        addSubview(bottomView)
        addSubview(playButton)
        addSubview(forwardLabel)
        addSubview(loadingView)
        
        bottomView.layer.addSublayer(gradientLayer)
        bottomView.addSubview(leftTimeLabel)
        bottomView.addSubview(bottomProgress)
        bottomView.addSubview(progressSlider)
        bottomView.addSubview(rightTimeLabel)
        bottomView.addSubview(muteButton)
        bottomView.addSubview(fullScreenBtn)
        bottomView.addSubview(backButton)
    }
    
    func setupGesture() {
        let tapGesture = UITapGestureRecognizer {[weak self] (_) in
            self?.showControlView()
        }
        self.addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = bounds.size.height
        let width = bounds.size.width
        
        playButton.height = 60
        playButton.width = 60
        playButton.center = CGPoint(x: width/2, y: height/2)
        
        loadingView.center = CGPoint(x: width/2, y: height/2)
        
        bottomView.frame = CGRect(x: 0, y: 0, width: width, height: height)
    
        backButton.frame = CGRect(10, 10, 16, 26)
        
        muteButton.height = 26
        muteButton.width = 26
        muteButton.left = 10
        muteButton.bottom = height - 10
        
        fullScreenBtn.height = 20
        fullScreenBtn.width = 20
        fullScreenBtn.right = bottomView.width - 10
        fullScreenBtn.bottom = height - 13
        
        leftTimeLabel.width = 35
        leftTimeLabel.height = 15
        leftTimeLabel.left = 45
        leftTimeLabel.bottom = height - 15
        
        rightTimeLabel.width = 35
        rightTimeLabel.height = 15
        rightTimeLabel.right = bottomView.width - 50
        rightTimeLabel.bottom = height - 15
        
        progressSlider.left = leftTimeLabel.right + 10
        progressSlider.width = rightTimeLabel.left - 10 - progressSlider.left
        progressSlider.height = 10
        progressSlider.centerY = leftTimeLabel.centerY
        
        forwardLabel.height = 50
        forwardLabel.width = 160
        forwardLabel.center = CGPoint(x: width/2, y: height/2)
        
        gradientLayer.frame = CGRect(x: 0, y: height - 40, width: width, height: 40)
        
        gestureProxyScrollView.frame = CGRect(x: 0, y: 0, width: width, height: height - 60)
        gestureProxyScrollView.contentSize = CGSize(width: gestureProxyScrollView.bounds.size.width + 1, height: gestureProxyScrollView.bounds.size.height)

    }
    
    func setupProperty() {
        
        isMute.registerValueChange {[weak self] (newValue, oldValue) in
            self?.muteButton.isSelected = !newValue
        }
        
        isFullScreen.registerValueChange {[weak self] (newValue, oldValue) in
            self?.fullScreenBtn.isSelected = !newValue
            self?.backButton.alpha = newValue ? 1 : 0
        }
        
        isPlaying.registerValueChange {[weak self] (newValue, oldValue) in
            self?.playButton.isSelected = !newValue
        }
        
        isBuffering.registerValueChange {[weak self] (newValue, oldValue) in
            if newValue {
                self?.loadingView.startAnimating()
            }
            else {
                self?.loadingView.stopAnimating()
            }
        }
    
        maximumDuration.registerValueChange {[weak self] (newValue, oldValue) in
            self?.progressSlider.maximumValue = newValue
        }
        
        currentTime.registerValueChange {[weak self] (newValue, oldValue) in
            if self?.isDragingSlider ?? true {
                return
            }
            self?.progressSlider.setValue(newValue, animated: false)
        }
        
    }
    
    func showControlView() {
        isShowControlView?.setValue(true, withDelay: 0)
        isShowControlView?.setValue(false, withDelay: 2)
    }
    
    func hideControlView() {
        isShowControlView?.setValue(false, withDelay: 0)
    }
    
    @objc private func stratDragSlide(slider: UISlider) {
        isDragingSlider = true
        leftTimeLabel.text = convertTime(second: CGFloat(progressSlider.value))
        showControlView()
    }
    
    @objc private func updateProgress(slider: UISlider) {
        isDragingSlider = false
        seekToTime.value = slider.value
        showControlView()
    }
    
    @objc private func onMute(sender: UIButton) {
        isMute.value = !isMute.value
        showControlView()
    }
    
    @objc private func onTapBackBtn(sender: UIButton) {
        isFullScreen.value = false
        showControlView()
    }
    
    @objc private func playOrPause(sender: UIButton) {
        isPlaying.value = !isPlaying.value
        if isPlaying.value {
            self.playButton.alpha = (isShowControlView?.currentValue ?? true) ? 1 : 0
        }
    }
    
    @objc private func fullScreenAction(sender: UIButton) {
        isFullScreen.value = !isFullScreen.value
        showControlView()
    }
    
    lazy private var originalPlaySecond: Float = 0
    lazy private var originalPoint: CGPoint = .zero
    lazy private var finalPoint: CGPoint = .zero
    
    @objc private func handleScrollGes(ges: UIPanGestureRecognizer) {
        if !canDrag { return }
        hideControlView()
        let location = ges.location(in: self)

        switch ges.state {
        case .began:
           
            bringSubview(toFront: forwardLabel)
            originalPoint = location
            originalPlaySecond = currentTime.value
            
        case .changed:
            forwardLabel.isHidden = false
            finalPoint = location
            let verValue: CGFloat = fabs(originalPoint.y - finalPoint.y)
            let horValue: CGFloat = fabs(originalPoint.x - finalPoint.x)
            if verValue <= horValue {
                forwardLabel.isHidden = originalPoint.equalTo(finalPoint)
                let forwardSecond: Float = Float((finalPoint.x - originalPoint.x) / self.width) * maximumDuration.value
                let a = min(max(originalPlaySecond + forwardSecond, 0), maximumDuration.value)
                forwardLabel.text = String.init(format: "%.1f", a - originalPlaySecond)
            }
        
        default:
            if finalPoint.equalTo(CGPoint.zero) { return }
            let forwardSecond: Float = Float((finalPoint.x - originalPoint.x) / self.width) * maximumDuration.value
            seekToTime.value = currentTime.value + min(max(originalPlaySecond + forwardSecond, 0), maximumDuration.value) - originalPlaySecond
            
            originalPoint = .zero
            finalPoint = .zero
            forwardLabel.isHidden = true
        }
    }
    
}
