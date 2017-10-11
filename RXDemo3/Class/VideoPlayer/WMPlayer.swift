//
//  WPlayer.swift
//  Meipu
//
//  Created by FuKai Yang on 2017/7/5.
//  Copyright © 2017年 Xiamen Meitu Technology Co., Ltd. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

fileprivate let kScreenWidth = UIScreen.main.bounds.size.width
fileprivate let kScreenHeight = UIScreen.main.bounds.size.height
fileprivate let leftFullscreenOfMute: CGFloat = 10.0

// 播放器的几种状态
enum WMPlayerState {
    case failed,           // 播放失败
         buffering,        // 缓冲中
         readyToPlay,      // 将要播放
         playing,          // 播放中
         paused,           // 播放暂停
         stopped,          // 暂停停止
         finished          // 播放完毕
}

//MARK - WMPlayerDelegate
protocol WMPlayerDelegate: class {
    /// 播放器事件
    // 点击播放暂停按钮代理方法
    func clickedPlayOrPause(_: WMPlayer, button: UIButton)
    // 点击关闭按钮代理方法
    func clickedCloseButton(_: WMPlayer, button: UIButton)
    // 点击全屏按钮代理方法
    func clickedFullScreenButton(_: WMPlayer, button: UIButton)
    // 单击WMPlayer的代理方法
    func singleTapped(_: WMPlayer, tap: UITapGestureRecognizer)
    // 双击WMPlayer的代理方法
    func doubleTapped(_: WMPlayer, tap: UITapGestureRecognizer)

    /// 播放状态
    // 播放失败的代理方法
    func failedPlayWithWMPlayerStatus(_: WMPlayer, state: WMPlayerState)
    // 准备播放的代理方法
    func readyToPlayWithWMPlayerStatus(_: WMPlayer, state: WMPlayerState)
    // 播放完毕的代理方法
    func finishedPlaye(_: WMPlayer)
}

extension WMPlayerDelegate {

    func clickedPlayOrPause(_ wmplayer: WMPlayer, button: UIButton) { }

    func clickedCloseButton(_ wmplayer: WMPlayer, button: UIButton) { }

    func clickedFullScreenButton(_ wmplayer: WMPlayer, button: UIButton) { }

    func singleTapped(_ wmplayer: WMPlayer, tap: UITapGestureRecognizer) { }

    func doubleTapped(_ wmplayer: WMPlayer, tap: UITapGestureRecognizer) { }

    func failedPlayWithWMPlayerStatus(_ wmplayer: WMPlayer, state: WMPlayerState) { }

    func readyToPlayWithWMPlayerStatus(_ wmplayer: WMPlayer, state: WMPlayerState) { }

    func finishedPlaye(_ wmplayer: WMPlayer) { }
}

class WMPlayer: UIView {

    fileprivate func WMPlayerSrcName(file: String) -> String {
        return "WMPlayer.bundle".stringByAppendingPathComponent(file)
    }

    fileprivate func WMPlayerFrameworkSrcName(file: String) -> String {
        return "Frameworks/WMPlayer.framework/WMPlayer.bundle".stringByAppendingPathComponent(file)
    }

    static var PlayViewStatusObservationContext: String = ""

    // 播放器player
    var player: MPAVPlayer? {
        willSet {
            if newValue != nil {
                if self.player?.currentItem == nil {
                    state = .paused
                } else {
                    state = .buffering
                }
                setProgressValue(value: 0)
                if self.player == newValue {
                    return
                }
                resetWMPlayer()
                currentItem = newValue?.currentItem
                newValue?.usesExternalPlaybackWhileExternalScreenIsActive = true
                syncScrubber()
            }
        }
    }
    // playerLayer,可以修改frame
    var playerLayer: AVPlayerLayer?
    var playerView : AVPlayerView?
    // 封面
    lazy var coverView = UIImageView()
    // avlayerSzie
    lazy var playItemSize = CGSize()
    // 播放器的代理
    weak var delegate: WMPlayerDelegate?
    // 底部操作工具栏
    lazy var bottomView = UIView()
    // 显示播放视频的title
    lazy var titleLabel = UILabel()
    // 播放器状态
    var state: WMPlayerState = .paused {
        didSet {
            switch state {
            case .failed:
                coverView.isHidden = false
                loadFailedView.isHidden = false
                loadingView.isHidden = true
                finishView.isHidden = true
                forwardLabel.isHidden = true
                playOrPauseBtn_Center.alpha = 0
                bringSubview(toFront: loadFailedView)

            case .buffering:
                loadFailedView.isHidden = true
                loadingView.isHidden = false
                finishView.isHidden = true
                forwardLabel.isHidden = true

            case .readyToPlay: break

            case .playing:
                loadFailedView.isHidden = true
                finishView.isHidden = true
                forwardLabel.isHidden = true

            case .paused:
                loadFailedView.isHidden = true
                loadingView.isHidden = true
                finishView.isHidden = true
                forwardLabel.isHidden = true

            case .stopped:
                coverView.isHidden = false
                loadFailedView.isHidden = true
                loadingView.isHidden = true
                finishView.isHidden = true
                forwardLabel.isHidden = true

            case .finished:
                loadFailedView.isHidden = true
                loadingView.isHidden = true
                finishView.isHidden = false
                forwardLabel.isHidden = true
                coverView.isHidden = false
            }
            loadingView.isHidden ? loadingView.stopAnimating() : loadingView.startAnimating()
        }
    }
    // BOOL值判断当前的状态
    @objc dynamic lazy var isFullscreen = Bool()
    // 控制全屏的按钮
    var fullScreenBtn = WMButton(type: .custom)
    // 静音按钮
    var muteButton = WMButton(type: .custom)
    // 播放暂停按钮(居中)
    lazy var playOrPauseBtn_Center = UIButton(type: .custom)
    // 显示加载失败的UILabel
    lazy var loadFailedView = UIView()
    // 当前播放的item
    var currentItem: AVPlayerItem? {
        willSet {
            if currentItem == newValue { return }
            if currentItem != nil {
                NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
                currentItem?.removeObserver(self, forKeyPath: "status")
                currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
                currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            }

            if newValue != nil {

//                newValue?.kvoController.observe(self, keyPath: "status", options: .new, block: {})
                newValue?.addObserver(self, forKeyPath: "status", options: .new, context: &WMPlayer.PlayViewStatusObservationContext)
                newValue?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: &WMPlayer.PlayViewStatusObservationContext)
                // 缓冲区空了，需要等待数据
                newValue?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: &WMPlayer.PlayViewStatusObservationContext)
                // 缓冲区有足够数据可以播放了
                newValue?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: &WMPlayer.PlayViewStatusObservationContext)

                // 添加视频播放结束通知
                NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: newValue)
            }
        }
    }
    // 菊花（加载框
    var loadingView = WMPlayerLoadingView()
    // 播放结束后的UI super view
    lazy var finishView = UIView()
    // BOOL值判断当前的播放状态
    var isPlaying: Bool {
        return !isPauseByUser
    }
    // 设置播放视频的USRLString,可以是本地的路径也可以是http的网络路径
    var URLString: String {
        guard let playerData = playerData else { return "" }
        return playerData.urlString
    }
    // 播放进度
    lazy var playProgress: Double = 0.0
    // 是否支持缓存
    lazy var supportCache = Bool()
    // 是否支持滑动屏幕拖动进度,默认NO
    var disableSildeForward = Bool() {
        didSet {
            fakeScrollView.gesEnabled = (!isDragingSlider && !self.disableSildeForward) || isFullscreen
            fakeScrollView.isScrollEnabled = (!isDragingSlider && !self.disableSildeForward) || isFullscreen
        }
    }
    // 跳到seekTime这个时间点播放
    lazy var seekTime: Double = 0.0

    var isPauseByUser = Bool() {
        didSet {
            playOrPauseBtn_Center.isSelected = isPauseByUser
        }
    }

    var playerData: MPAVPlayerData? {
        willSet {
            if playerData != newValue {
                resetWMPlayer()
            }

            if player == nil {
                player = newValue?.player
            }
            guard let player = player else { return }

            if playerLayer == nil {
                playerView = AVPlayerView(player: player)
                playerLayer = (playerView?.layer as! AVPlayerLayer)
                playerView?.frame = bounds
                insertSubview(playerView!, at: 0)
                refreshGravity()
            }
            videoSize = newValue?.size ?? .zero
            seekTime = CMTimeGetSeconds((newValue?.seekTime)!)
            muteButton.isSelected = player.volume == 1
            muteButton2.isSelected = player.volume == 1
            isMuteForNormalState = !(player.volume > Float(0))
        }
    }
    // 视频的高与宽
    var videoSize: CGSize = .zero {
        didSet {
            refreshGravity()
        }
    }

    lazy var isPortrait = Bool()

    @objc dynamic lazy var isShowControlView = Bool()

    var hasControlView = Bool() {
        didSet {
            muteButton2.isHidden = needShowControlView()
            fullScreenBtn2.isHidden = needShowControlView()
        }
    }

    func refreshGravity() {
        if isFullscreen {
            if videoSize.height/videoSize.width > kScreenHeight/kScreenWidth {
                playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                coverView.contentMode = .scaleAspectFill
                coverView.backgroundColor = .white
            } else {
                playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
                coverView.contentMode = .scaleAspectFit
                coverView.backgroundColor = .clear
            }
        } else {
            playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            coverView.contentMode = .scaleAspectFill
            coverView.backgroundColor = .white
        }
    }

    fileprivate var canDrag: Bool {
        return (!isDragingSlider) && (state == .buffering || state == .paused || state == .playing || state == .readyToPlay || state == .paused)
    }

    lazy fileprivate var originalPlaySecond = TimeInterval()
    lazy fileprivate var originalPoint = CGPoint()
    lazy fileprivate var finalPoint = CGPoint()
    lazy fileprivate var dateFormatter = DateFormatter()

    fileprivate var videoDuration: CGFloat = 0 {
        willSet {
            if newValue != 0 {
                rightTimeLabel.text = convertTime(second: newValue)
                progressSlider.maximumValue = Float(newValue)
            }
        }
    }

    fileprivate var playbackTimeObserver: Any?

    lazy fileprivate var isStopByBackground = Bool()
    lazy fileprivate var isBuffering = Bool()
    lazy fileprivate var isMuteForNormalState = Bool()
    lazy fileprivate var isSeekingAtStart = Bool()
    fileprivate var isDragingSlider = Bool() {
        didSet {
            fakeScrollView.gesEnabled = (!self.isDragingSlider && !disableSildeForward) || isFullscreen
            fakeScrollView.isScrollEnabled = (!self.isDragingSlider && !disableSildeForward) || isFullscreen
        }
    }

    lazy fileprivate var tap = UITapGestureRecognizer()
    fileprivate var fullScreenBtn2 = WMButton(type: UIButtonType.custom)
    lazy fileprivate var leftTimeLabel = UILabel()
    lazy fileprivate var rightTimeLabel = UILabel()
    lazy fileprivate var forwardLabel = UILabel()
    lazy fileprivate var progressSlider = UISlider()
    lazy fileprivate var gradient = CAGradientLayer()
    lazy fileprivate var loadingProgress = UIProgressView(progressViewStyle: UIProgressViewStyle.default)
    lazy fileprivate var bottomProgress = UIView()
    fileprivate var fakeScrollView = WMProxyScrollView()
    fileprivate var backButton = WMButton()
    // 静音按钮2
    fileprivate var muteButton2 = WMButton()
    lazy fileprivate var loadFailedLabel = UILabel()
    lazy fileprivate var loadFailedButton = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: 30))

    lazy fileprivate var singleTap = UITapGestureRecognizer()
    lazy fileprivate var smallSuperView = UIView()
    lazy fileprivate var smallFrame = CGRect()

    //MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        initWMPlayer()
    }

    init(frame: CGRect, supportCache: Bool) {
        super.init(frame: frame)
        self.supportCache = supportCache

        initWMPlayer()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initWMPlayer()
    }

    init() {
        super.init(frame: CGRect.zero)
        initWMPlayer()
    }

    fileprivate func initWMPlayer() {
        hasControlView = true
        seekTime = 0.00
        isPortrait = true
        backgroundColor = .black

        initSubViews()

        reloadLayout(isFullScreen: false)

        singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        addGestureRecognizer(singleTap)
        changeIsShowControlView(false, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initSubViews() {
        loadingView = WMPlayerLoadingView(frame: CGRect(x: 0, y: 0, width: 52, height: 52))
        addSubview(loadingView)

        fakeScrollView = WMProxyScrollView(frame: bounds)
        fakeScrollView.gesEnabled = true
        fakeScrollView.showsVerticalScrollIndicator = false
        fakeScrollView.showsHorizontalScrollIndicator = false
        insertSubview(fakeScrollView, at: 0)
        addGestureRecognizer(fakeScrollView.panGestureRecognizer)
        fakeScrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollGes(ges:)))
        fakeScrollView.isUserInteractionEnabled = false

        coverView = UIImageView()
        coverView.backgroundColor = .white
        coverView.contentMode = .scaleAspectFill
        addSubview(coverView)

        bottomView = UIView()
        bottomView.addGestureRecognizer(UITapGestureRecognizer())
        addSubview(bottomView)

        let colorTop = UIColor(white: 0, alpha: 0)
        let colorBottom = UIColor(white: 0, alpha: 0.6)

        gradient = CAGradientLayer()
        gradient.colors = Array(arrayLiteral: colorTop.cgColor, colorBottom.cgColor)
        gradient.locations = [0, 1]
        gradient.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        bottomView.layer.insertSublayer(gradient, at: 0)

        muteButton = WMButton(type: .custom)
        muteButton.hitExpand = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        muteButton.showsTouchWhenHighlighted = true
        muteButton.addTarget(self, action: #selector(onMute(sender:)), for: .touchUpInside)
        muteButton.setImage(UIImage(named: "icon_mute"), for: .normal)
        muteButton.setImage(UIImage(named: "icon_no_mute"), for: .selected)
        bottomView.addSubview(muteButton)

        muteButton2 = WMButton(type: .custom)
        muteButton2.hitExpand = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        muteButton2.showsTouchWhenHighlighted = true
        muteButton2.addTarget(self, action: #selector(onMute(sender:)), for: .touchUpInside)
        muteButton2.setImage(UIImage(named: "icon_mute"), for: .normal)
        muteButton2.setImage(UIImage(named: "icon_no_mute"), for: .selected)
        muteButton2.isHidden = true
        addSubview(muteButton2)

        loadingProgress = UIProgressView(progressViewStyle: .default)
        loadingProgress.progressTintColor = UIColor(white: 1, alpha: 0.2)
        loadingProgress.trackTintColor = .clear
        loadingProgress.backgroundColor = .clear
        bottomView.addSubview(loadingProgress)
        loadingProgress.setProgress(0.0, animated: false)
        bottomView.sendSubview(toBack: loadingProgress)

        fullScreenBtn = WMButton(type: .custom)
        fullScreenBtn.hitExpand = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)
        fullScreenBtn.showsTouchWhenHighlighted = true
        fullScreenBtn.addTarget(self, action: #selector(fullScreenAction(sender:)), for: .touchUpInside)
        fullScreenBtn.setImage(UIImage(named: "icon_fullscreen"), for: .normal)
        fullScreenBtn.setImage(UIImage(named: "video_quit_fullscreen"), for: .selected)
        bottomView.addSubview(fullScreenBtn)

        fullScreenBtn2 = WMButton(type: .custom)
        fullScreenBtn2.hitExpand = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)
        fullScreenBtn2.showsTouchWhenHighlighted = true
        fullScreenBtn2.addTarget(self, action: #selector(fullScreenAction(sender:)), for: .touchUpInside)
        fullScreenBtn2.setImage(UIImage(named: "icon_fullscreen"), for: .normal)
        fullScreenBtn2.setImage(UIImage(named: "video_quit_fullscreen"), for: .selected)
        addSubview(fullScreenBtn2)
        fullScreenBtn2.isHidden = true

        leftTimeLabel = UILabel()
        leftTimeLabel.text = "00:00"
        leftTimeLabel.textAlignment = .left
        leftTimeLabel.textColor = .white
        leftTimeLabel.backgroundColor = .clear
        leftTimeLabel.font = UIFont.systemFont(ofSize: 11)
        bottomView.addSubview(leftTimeLabel)

        rightTimeLabel = UILabel()
        rightTimeLabel.text = "00:00"
        rightTimeLabel.textAlignment = .right
        rightTimeLabel.textColor = .white
        rightTimeLabel.backgroundColor = .clear
        rightTimeLabel.font = UIFont.systemFont(ofSize: 11)
        bottomView.addSubview(rightTimeLabel)

        progressSlider = UISlider()
        progressSlider.backgroundColor = .clear
        progressSlider.minimumValue = 0.0
        progressSlider.setThumbImage(UIImage(named: "video_dot"), for: .normal)
        progressSlider.minimumTrackTintColor = UIColor(red: 1, green: 0, blue: 76/255, alpha: 1)
        progressSlider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.2)
        progressSlider.value = 0.0
        progressSlider.addTarget(self, action: #selector(stratDragSlide(slider:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(updateProgress(slider:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        tap = UITapGestureRecognizer(target: self, action: #selector(actionTapGesture(sender:)))
        tap.delegate = self
        fakeScrollView.panGestureRecognizer.require(toFail: tap)

        progressSlider.addGestureRecognizer(tap)
        bottomView.addSubview(progressSlider)

        playOrPauseBtn_Center = UIButton(type: .custom)
        playOrPauseBtn_Center.showsTouchWhenHighlighted = true
        playOrPauseBtn_Center.addTarget(self, action: #selector(playOrPause(_:)), for: .touchUpInside)
        playOrPauseBtn_Center.setImage(UIImage(named: "icon_video_pause_new"), for: .normal)
        playOrPauseBtn_Center.setImage(UIImage(named: "icon_video_play_new"), for: .selected)
        playOrPauseBtn_Center.alpha = 0
        addSubview(playOrPauseBtn_Center)

        forwardLabel = UILabel()
        forwardLabel.isHidden = true
        forwardLabel.textColor = .white
        forwardLabel.font = UIFont.systemFont(ofSize: 20)
        forwardLabel.textAlignment = .center
        forwardLabel.backgroundColor = UIColor(white: 0, alpha: 0.4)
        forwardLabel.layer.cornerRadius = 6
        forwardLabel.layer.masksToBounds = true
        forwardLabel.numberOfLines = 0
        addSubview(forwardLabel)

        bottomProgress = UIView()
        bottomProgress.backgroundColor = UIColor(red: 1, green: 0, blue: 76/255, alpha: 1)
        addSubview(bottomProgress)

        finishView = UIView()
        finishView.isUserInteractionEnabled = true
        let finishTap = UITapGestureRecognizer(target: self, action: #selector(onTapFinish))
        finishView.addGestureRecognizer(finishTap)
        finishView.isHidden = true
        finishView.backgroundColor = UIColor(white: 0, alpha: 0.88)
        addSubview(finishView)

        backButton = WMButton()
        backButton.hitExpand = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        backButton.setImage(UIImage(named: "video_back"), for: .normal)
        backButton.addTarget(self, action: #selector(onTapBackBtn), for: .touchUpInside)
        addSubview(backButton)

        loadFailedView = UIView()
        loadFailedView.isHidden = true
        loadFailedView.addGestureRecognizer(UITapGestureRecognizer())
        loadFailedView.isUserInteractionEnabled = true
        loadFailedView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        addSubview(loadFailedView)

        loadFailedLabel = UILabel()
        loadFailedLabel.textAlignment = .center
        loadFailedLabel.textColor = .white
        loadFailedLabel.font = UIFont.mpLightFontOfSize(15)
        loadFailedLabel.text = "视频加载失败"
        loadFailedView.addSubview(loadFailedLabel)

        loadFailedButton = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: 30))
        loadFailedButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 76/255, alpha: 1).cgColor
        loadFailedButton.layer.cornerRadius = 4
        loadFailedButton.layer.borderWidth = 0.5
        loadFailedButton.setTitle("点击重试", for: .normal)
        loadFailedButton.setTitleColor(UIColor(red: 1, green: 0, blue: 76/255, alpha: 1), for: .normal)
        loadFailedButton.addTarget(self, action: #selector(restartPlay), for: .touchUpInside)
        loadFailedButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        loadFailedView.addSubview(loadFailedButton)

        bringSubview(toFront: loadingView)
        bringSubview(toFront: bottomView)
        bringSubview(toFront: fullScreenBtn)
        bringSubview(toFront: fullScreenBtn2)
        bringSubview(toFront: playOrPauseBtn_Center)
        bringSubview(toFront: finishView)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }



    //MARK: - 单击手势方法
    @objc fileprivate func handleSingleTap(sender: UITapGestureRecognizer) {
        delegate?.singleTapped(self, tap: sender)
        if needShowControlView() {
            changeIsShowControlView(!isShowControlView, animated: true)
        } else {
            playOrPause(playOrPauseBtn_Center)
        }
    }

    //MARK: - 双击手势方法
    fileprivate func handleDoubleTap(doubleTap: UITapGestureRecognizer) {
        delegate?.doubleTapped(self, tap: doubleTap)
    }

    //MARK: - Setter
    fileprivate func setCurrentTime(time: Double) {
        DispatchQueue.main.async {
            let dragedSeconds = floorf(Float(time))
            self.seekToTime(time: Double(dragedSeconds))
        }
    }

    fileprivate func setProgressValue(value: Double) {
        if videoDuration == 0 { return }
        if !isDragingSlider {
            leftTimeLabel.text = convertTime(second: CGFloat(value))
            progressSlider.value = Float(value)
            playProgress = value
        }
        let process = value / Double(videoDuration)
        bottomProgress.frame = CGRect(x: bottomView.frame.origin.x, y: bottomView.frame.origin.y + bottomView.frame.size.height - 3, width: bottomView.frame.size.width * CGFloat(process), height: 3)
    }

    fileprivate func refreshCurrentTime(currentTime: CGFloat) {
        setProgressValue(value: Double(currentTime))
    }

    //MARK: - 开始点击sidle
    @objc fileprivate func stratDragSlide(slider: UISlider) {
        isDragingSlider = true
        leftTimeLabel.text = convertTime(second: CGFloat(progressSlider.value))
        setProgressValue(value: Double(slider.value))
        cancelControlViewHide()

    }

    //MARK: - 播放进度
    @objc fileprivate func updateProgress(slider: UISlider) {
        isDragingSlider = false

        if fabsf(progressSlider.value - progressSlider.maximumValue) < 0.01 {
            moviePlayDidEnd(notification: nil)
        } else {
            guard let currentItem = self.currentItem else { return }
            let total = CGFloat(currentItem.duration.value) / CGFloat(currentItem.duration.timescale)
            let dragedSeconds = floorf(Float(total) * progressSlider.value / progressSlider.maximumValue)
            seekToTime(time: Double(dragedSeconds))
            if state == WMPlayerState.finished {
                play()
            }
            changeIsShowControlView(isShowControlView, animated: true)
        }
    }

    //MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &WMPlayer.PlayViewStatusObservationContext {
            if videoSize.equalTo(.zero) {
                guard let currentItem = currentItem else { return }
                let array = currentItem.asset.tracks
                for track in array {
                    if track.mediaType == AVMediaType.video {
                        videoSize = track.naturalSize
                        reloadLayout(isFullScreen: isFullscreen)
                        break
                    }
                }
            }

            guard let currentItem = currentItem else { return }

            if keyPath == "status" {
//                let status = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItemStatus
//                guard let status = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItemStatus else { return }
                playItemStatusHasChange(status: currentItem.status)
            } else if keyPath == "loadedTimeRanges" {
                // 计算缓冲进度
                let timeInterval = availableDuration()
                let duration = currentItem.duration
                let totalDuration = CMTimeGetSeconds(duration)

                // 缓冲颜色
                loadingProgress.setProgress(Float(timeInterval/totalDuration), animated: false)
            } else if keyPath == "playbackBufferEmpty" {
                // 当缓冲是空的时候
                if currentItem.isPlaybackBufferEmpty {
                    state = .buffering
                    loadedTimeRanges()
                }
            } else if keyPath == "playbackLikelyToKeepUp" {
                // 当缓冲好的时候
                if currentItem.isPlaybackLikelyToKeepUp && state == .buffering {
                    state = .playing
                }
            }
        }
    }

    fileprivate func needBuffer() -> Bool {
        if currentItem != nil {
            guard let currentItem = currentItem else { return false }
            if currentItem.isPlaybackBufferEmpty == true && currentItem.status != .readyToPlay {
                return true
            }
            return false
        } else {
            return false
        }
    }

    fileprivate func playItemStatusHasChange(status: AVPlayerItemStatus) {
        switch status {
        case .unknown:
            loadingProgress.setProgress(0, animated: false)
            if currentItem == nil {
                state = .paused
            } else {
                state = .buffering
            }

        case .readyToPlay:
            if !isPauseByUser {
                state = .playing
            }

            guard let currentItem = currentItem else { return }
            if CMTimeGetSeconds(currentItem.duration) > 0 {
                let _x = CMTimeGetSeconds(currentItem.duration)
                if !_x.isNaN {
                    guard let playerItem = player?.currentItem else { return }
                    videoDuration = CGFloat(CMTimeGetSeconds(playerItem.duration))
                }
            }

            // 监听播放状态
            initTimer()

            delegate?.readyToPlayWithWMPlayerStatus(self, state: .readyToPlay)

            // 跳到xx秒播放视频
            if seekTime > 0 {
                seekToTimeToPlayAtStart(time: floor(seekTime))
            } else if !isPauseByUser {
                player?.pause()
                player?.play()
            }

        case .failed:
            loadFailed()
        }
    }

    fileprivate func playItemLoadedTimeRangesHasChange() {
        let timeInterval = availableDuration()
        guard let currentItem = currentItem else { return }
        let duration = currentItem.duration
        let totalDuration = CMTimeGetSeconds(duration)

        // 缓冲颜色
        loadingProgress.setProgress(Float(timeInterval/totalDuration), animated: false)
    }

    fileprivate func playItemPlaybackBufferEmptyHasChange() {
        guard let currentItem = currentItem else { return }
        if currentItem.isPlaybackBufferEmpty {
            state = .buffering

        }
    }

    // 缓冲回调
    fileprivate func loadedTimeRanges() {
        if isPlaying || state == .buffering || state == .playing || state == .readyToPlay {
            if isBuffering { return }
            isBuffering = true
            player?.pause()
            state = .buffering
            DispatchQueue.main.asyncAfter(deadline: .now()+1.5) { [weak self] in
                guard let sSelf = self else { return }
                sSelf.isBuffering = false
                if sSelf.isPlaying || sSelf.state == .buffering || sSelf.state == .playing || sSelf.state == .readyToPlay {
                    guard let currentItem = sSelf.currentItem else { return }
                    if !currentItem.isPlaybackLikelyToKeepUp {
                        sSelf.loadedTimeRanges()
                    } else {
                        sSelf.play()
                    }
                }
            }
        }
    }

    //MARK: - 定时器

    fileprivate func initTimer() {
//        var interval: Double = 0.1
        let playerDuration = playerItemDuration()

        if CMTIME_IS_INVALID(playerDuration) { return }

//        let duration = CMTimeGetSeconds(playerDuration)
//        if duration.isFinite {
//            let width = progressSlider.bounds.width
//            interval = 0.5 * duration / Double(width)
//        }

        playbackTimeObserver = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 30), queue: DispatchQueue.main) { [weak self] (time: CMTime) in
            guard let sSelf = self else { return }
            sSelf.syncScrubber()
        }
    }

    fileprivate func seekToTime(time: Double) {
        isSeekingAtStart = false
        guard let player = player else { return }
        guard let status = player.currentItem?.status else { return }
        var time1: Double = time
        if status == AVPlayerItemStatus.readyToPlay {
            if time1 > duration() {
                time1 = duration()
            }
            if time1 <= 0 {
                time1 = 0
            }
            let needPlay = isPlaying
            player.pause()
            if isPlaying {
                loadingView.startAnimating()
            }

            player.seek(to: CMTime(value: CMTimeValue(time1), timescale: 1), toleranceBefore: CMTime(value: 1, timescale: 1), toleranceAfter: CMTime(value: 1, timescale: 1)) { [weak self] (finished: Bool) in
                guard let sSelf = self else { return }
                if needPlay {
                    sSelf.play()
                }
                sSelf.seekTime = 0
            }
        }
    }

    func convertTime(second: CGFloat) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(second))
        if second/3600 >= 1 {
            dateFormatter.dateFormat = "HH:mm:ss"
        } else {
            dateFormatter.dateFormat = "mm:ss"
        }
        let newTime = dateFormatter.string(from: d)
        return newTime
    }

    /**
     *  计算缓冲进度
     *
     *  @return 缓冲进度
     */
    fileprivate func availableDuration() -> TimeInterval{
        guard let currentItem = currentItem else { return 0 }
        let loadedTimeRanges = currentItem.loadedTimeRanges
        guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return 0 }      // 获取缓冲区域
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        return startSeconds + durationSeconds                                       // 计算缓冲总进度
    }

    func resetWMPlayer() {
        isPauseByUser = true
        recordPlayerData()
        resetUI()
        cleanPlayerResource()
    }

    fileprivate func cleanPlayerResource() {
        videoSize = playerData?.size ?? .zero
        if playbackTimeObserver != nil {
            player?.removeTimeObserver(playbackTimeObserver as Any)
            playbackTimeObserver = nil
        }
        playerView?.removeFromSuperview()
        player?.replaceCurrentItem(with: nil)        // 不调用可能会产生addsubview卡住的问题
        self.player = nil
        currentItem = nil
        playerLayer = nil
        playerView = nil
        videoDuration = 0
    }

    fileprivate func resetUI() {
        changeIsShowControlView(false, animated: false)
        setProgressValue(value: 0)
        coverView.isHidden = false
        seekTime = 0
        leftTimeLabel.text = "00:00"
        rightTimeLabel.text = "00:00"
        coverView.contentMode = .scaleAspectFill
        coverView.backgroundColor = .white
    }

    fileprivate func recordPlayerData() {
        if currentItem != nil {
            playerData?.seekTime = (currentItem?.currentTime())!
        }
        guard let player = player else { return }
        playerData?.isMute = player.volume == 0
    }

    fileprivate func syncScrubber() {
        let duration = videoDuration
        guard let player = player else { return }
        if player.rate == 0 {
            // 若播放器已停止播放，放弃同步
            return
        }

        if duration.isFinite {
            let nowTime = CMTimeGetSeconds(player.currentTime())
            if nowTime > 0 && !needBuffer() {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { [weak self] in
                    guard let sSelf = self else { return }
                    if sSelf.state != .stopped && sSelf.state != .failed && sSelf.state != .finished {
                        if sSelf.isSeekingAtStart == false {
                            sSelf.coverView.isHidden = true
                        }
                    }
                }
            }
            loadingView.stopAnimating()

            refreshCurrentTime(currentTime: CGFloat(nowTime))
        }
    }

    /**pi
     *  跳到time处播放
     *  @param seekTime这个时刻，这个时间点
     */
    fileprivate func seekToTimeToPlayAtStart(time: Double) {
        guard let player = player else { return }
        guard let status = player.currentItem?.status else { return }
        var time = time
        if status == .readyToPlay {
            if time > duration() {
                time = duration()
            }
            if time <= 0 {
                time = 0
            }
            isSeekingAtStart = true

            player.seek(to: CMTime(value: CMTimeValue(time), timescale: 1), toleranceBefore: CMTime(value: 1, timescale: 1), toleranceAfter: CMTime(value: 1, timescale: 1)) { [weak self] (Bool) in
                guard let sSelf = self else { return }
                sSelf.coverView.isHidden = true
                sSelf.isSeekingAtStart = false
                sSelf.seekTime = 0
            }
        }
    }

    func videoDurationStr() -> String {
        if videoDuration == 0 {
            return ""
        }
        return convertTime(second: videoDuration)
    }

    fileprivate func playerItemDuration() -> CMTime {
        guard let playerItem = currentItem else { return kCMTimeInvalid }
        if playerItem.status == .readyToPlay {
            return playerItem.duration
        }
        return kCMTimeInvalid
    }

    deinit {
        resetWMPlayer()
    }

    fileprivate func version() -> String{
        return "2.0.0"
    }

    //MARK: - 重新布局Autolayout
    fileprivate func reloadLayout(isFullScreen: Bool) {
        fakeScrollView.gesEnabled = (!isDragingSlider && !disableSildeForward && !isFullScreen)
        fakeScrollView.isScrollEnabled = (!isDragingSlider && !disableSildeForward && !isFullScreen)

        fullScreenBtn.isSelected = isFullScreen
        fullScreenBtn2.isSelected = isFullScreen

        changeIsShowControlView(isShowControlView, animated: false)

        muteButton2.isHidden = needShowControlView()
        fullScreenBtn2.isHidden = needShowControlView()

        backButton.alpha = (!isFullScreen || isShowControlView) ? 0 : 1

        let height = bounds.size.height
        let width = bounds.size.width

        loadingView.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)

        backButton.width = 16
        backButton.height = 26
        backButton.left = 10
        backButton.top = 10

        bottomView.frame = CGRect(x: 0, y: height - 40, width: width, height: 40)

        muteButton.height = 26
        muteButton.width = 26
        muteButton.left = 10
        muteButton.bottom = bottomView.height - 10

        muteButton2.height = 26
        muteButton2.width = 26
        muteButton2.left = 10
        muteButton2.bottom = self.height - 10

        fullScreenBtn.height = 20
        fullScreenBtn.width = 20
        fullScreenBtn.right = bottomView.width - 10
        fullScreenBtn.bottom = bottomView.height - 13

        fullScreenBtn2.height = 20
        fullScreenBtn2.width = 20
        fullScreenBtn2.right = self.width - 10
        fullScreenBtn2.bottom = self.height - 13

        leftTimeLabel.width = 35
        leftTimeLabel.height = 15
        leftTimeLabel.left = 45
        leftTimeLabel.bottom = bottomView.height - 15

        rightTimeLabel.width = 35
        rightTimeLabel.height = 15
        rightTimeLabel.right = bottomView.width - 50
        rightTimeLabel.bottom = bottomView.height - 15

        progressSlider.left = leftTimeLabel.right + 10
        progressSlider.width = rightTimeLabel.left - 10 - progressSlider.left
        progressSlider.height = 10
        progressSlider.centerY = leftTimeLabel.centerY

        loadingProgress.width = progressSlider.width - 4
        loadingProgress.height = 2
        loadingProgress.left = progressSlider.left + 2
        loadingProgress.centerY = progressSlider.centerY

        loadFailedView.frame = bounds

        loadFailedLabel.height = 30
        loadFailedLabel.width  = 120
        loadFailedLabel.centerY = loadFailedView.height/2 - 20
        loadFailedLabel.centerX = loadFailedView.width/2

        loadFailedButton.height = 30
        loadFailedButton.width  = 120
        loadFailedButton.top = loadFailedLabel.bottom + 17
        loadFailedButton.centerX = loadFailedView.width/2

        finishView.frame = bounds

        playOrPauseBtn_Center.height = 60
        playOrPauseBtn_Center.width = 60
        playOrPauseBtn_Center.center = CGPoint(x: width/2, y: height/2)

        forwardLabel.height = 50
        forwardLabel.width = 160
        forwardLabel.center = CGPoint(x: width/2, y: height/2)

        coverView.frame = bounds

        gradient.frame = bottomView.bounds

        loadingView.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)

        let process: CGFloat = CGFloat(progressSlider.value / progressSlider.maximumValue)
        bottomProgress.frame = CGRect(x: bottomView.frame.origin.x, y: bottomView.frame.origin.y + bottomView.frame.size.height - 3, width: bottomView.frame.size.width*process, height: 3)

        fakeScrollView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - (isFullscreen ? 60 : 0 ))
        fakeScrollView.contentSize = CGSize(width: fakeScrollView.bounds.size.width + 1, height: fakeScrollView.bounds.size.height)
        fakeScrollView.bounces = false

    }

    fileprivate func getSize(width: CGFloat, font: UIFont, text: String) -> CGSize {
        let lable = UILabel()
        lable.font = font
        lable.numberOfLines = 0
        lable.text = text
        let size = lable.sizeThatFits(CGSize(width: width, height: 0))
        return size
    }

    fileprivate func needShowControlView() -> Bool {
        return hasControlView || isFullscreen
    }

    //MARK: - MP

    func toFullScreen(interfaceOrientation: UIInterfaceOrientation) {
        isFullscreen = true
        UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.fade)
        guard let player = player  else { return }
        isMuteForNormalState = player.volume > 0 ? false : true
        setMute(isMute: false)
        var duration: TimeInterval = 0.4
        if videoSize.width <= videoSize.height {
            duration = 0
        }

        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let sSelf = self else { return }
            sSelf.refreshGravity()
            sSelf.toFullScreenWithInterfaceOrientation(interfaceOrientation: interfaceOrientation)
            sSelf.superview?.layoutIfNeeded()
            }, completion: nil)
    }

    fileprivate func toFullScreenWithInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation)
    {
        removeFromSuperview()
        guard let playerView = playerView else { return }
        if videoSize.width <= videoSize.height {
            isPortrait = true
            frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
            playerView.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
            reloadLayout(isFullScreen: true)
        } else {
            playerView.frame = bounds
            reloadLayout(isFullScreen: true)
            if interfaceOrientation == UIInterfaceOrientation.landscapeLeft {
                transform = CGAffineTransform.init(rotationAngle: -.pi/2)
            } else {
                transform = CGAffineTransform.init(rotationAngle: .pi/2)
            }
            frame = CGRect(x:0, y:0, width:kScreenWidth , height:  kScreenHeight)
            isPortrait = false
        }
        UIApplication.shared.keyWindow?.addSubview(self)
        bringSubview(toFront: bottomView)
        bringSubview(toFront: muteButton)
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }

    func toSmallScreen() {
        setMute(isMute: isMuteForNormalState)
        toSmallScreen(animated: true)
    }

    func toSmallScreen(animated: Bool) {
        isFullscreen = false
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.none)
        smallSuperView.viewController()?.view.setNeedsLayout()
        removeFromSuperview()
        isPortrait = true

        self.smallSuperView.addSubview(self)
        let doBlock = { [weak self] in
            guard let sSelf = self else { return }
            sSelf.transform = CGAffineTransform.identity
            sSelf.frame = sSelf.smallFrame
            sSelf.playerView?.frame = sSelf.bounds
            
            sSelf.refreshGravity()
            sSelf.reloadLayout(isFullScreen: false)
        }

        if animated {
            muteButton.isHidden = true
            UIView.animate(withDuration: 0.4, animations: doBlock, completion: { [weak self](finished: Bool) -> Void in
                guard let sSelf = self else { return }
                sSelf.muteButton.isHidden = false
            })
        } else {
            doBlock()
        }
    }

    fileprivate func loadFailed() {
        state = WMPlayerState.failed
        delegate?.failedPlayWithWMPlayerStatus(self, state: WMPlayerState.failed)

        bringSubview(toFront: loadFailedView)
    }

    func leftOfMuteButton() -> CGFloat {
        return 10.0
    }


    func play() {
        if state == .failed {
            print("sometingwrong play")
            return
        }
        let currentTime = self.currentTime()
        if currentTime != 0 && currentTime == duration() {
            setCurrentTime(time: 0)
        }
        if player == nil && playerData != nil{
            guard let playerData = playerData else { return }
            self.playerData = playerData
        }
        guard let player = player else { return }
        player.play()
        loadingView.startAnimating()
        isPauseByUser = false
        playerData?.isPausedByUser = false
        changeIsShowControlView(isShowControlView, animated: false)
        guard let currentItem = currentItem else { return }
        if currentItem.status == .readyToPlay {
            if state != .stopped {
                if currentItem.isPlaybackBufferEmpty {

                    if NSFoundationVersionNumber >= NSFoundationVersionNumber10_0 {
                        state = .playing
                    } else {
                        state = .playing
                    }
                } else {
                    state = .playing
                }
            }
        } else if currentItem.status == .unknown {
            state = .buffering
        } else if currentItem.status == .failed {
            restartPlay()
        }
    }

    func pause() {
        if state == .failed {
            print("somethingwrong pause")
            return
        }
        if currentItem != nil {
            guard let currentItem = currentItem else { return }
            playerData?.seekTime = currentItem.currentTime()
        }
        playerData?.isMute = player?.volume == 0
        player?.pause()
        isPauseByUser = true
        if state == .playing || state == .buffering {
            state = .paused
        }
    }

    func stop() {
        stopVideo()
    }

    func stopVideo() {
        removeFromSuperview()
        playerData = nil 
        state = .stopped
    }

    fileprivate func finishVideo() {
        state = .finished
        guard let player = player else { return }
        player.seek(to: kCMTimeZero) { [weak self] (finished: Bool) in
            guard let sSelf = self else { return }
            sSelf.setProgressValue(value: 0)
            sSelf.isPauseByUser = true
            sSelf.changeIsShowControlView(false, animated: false)
            sSelf.delegate?.finishedPlaye(sSelf)
            sSelf.pause()
            sSelf.resetWMPlayer()
        }
    }

    func suspend() {
        pause()
        resetWMPlayer()
        state = .stopped
    }

    func currentTime() -> Double {
        guard let player = player else { return 0 }
        return CMTimeGetSeconds(player.currentTime())
    }

    @objc func playOrPause(_ sender: UIButton?) {
        if isPauseByUser == true {
            play()
            playerData?.isPausedByUser = false
        } else {
            pause()
            playerData?.isPausedByUser = true
        }
        changeIsShowControlView(isShowControlView, animated: true)
        guard let sender = sender else { return }
        delegate?.clickedPlayOrPause(self, button: sender)
    }

    @objc fileprivate func actionTapGesture(sender: UITapGestureRecognizer) {
        if isDragingSlider { return }
        let touchLocation = sender.location(in: progressSlider)
        let value = (progressSlider.maximumValue - progressSlider.minimumValue) * Float(touchLocation.x / progressSlider.frame.size.width)
        setProgressValue(value: Double(value))
        guard let currentItem = currentItem else { return }
        let total = Float(currentItem.duration.value) / Float(currentItem.duration.timescale)
        let dragedSeconds = floorf(total * progressSlider.value / progressSlider.maximumValue)
        seekToTime(time: Double(dragedSeconds))
        changeIsShowControlView(isShowControlView, animated: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadLayout(isFullScreen: isFullscreen)
        guard let playerView = playerView else { return }
        playerView.frame = bounds
    }

    @objc fileprivate func onTapBackBtn() {
        if isFullscreen {
            toSmallScreen()
        }
    }

    @objc fileprivate func fullScreenAction(sender: UIButton) {
        
        guard videoSize.width != 0 && videoSize.height != 0 else {
            return
        }
        if isFullscreen {
            toSmallScreen()
        } else {
            guard let superview = superview else { return }
            smallSuperView = superview
            smallFrame = frame
            toFullScreen(interfaceOrientation: .landscapeRight)
        }

        delegate?.clickedFullScreenButton(self, button: sender)
        delayControlViewHide()
    }

    @objc fileprivate func restartPlay() {
        guard let currentItem = currentItem else { return }
        if (currentItem.asset as? AVURLAsset) != nil {
            resetWMPlayer()
            coverView.isHidden = false
//            playerData = playerData
            state = .buffering
            play()
        }
    }

    @objc fileprivate func onTapFinish() {
        if isFullscreen {
            toSmallScreen()
        }
    }

    @objc fileprivate func onMute(sender: UIButton) {
        setMute(isMute: sender.isSelected)
        delayControlViewHide()
    }

    fileprivate func setMute(isMute: Bool) {
        muteButton.isSelected = !isMute
        muteButton2.isSelected = !isMute
        guard let player = player else { return }
        player.volume = isMute ? 0 : 1
        playerData?.isMute = isMute
        if player.rate == 1 {
            player.pause()
            player.play()
        }
    }

    fileprivate func duration() -> Double {
        guard let player = player else { return 0 }
        guard let playerItem = player.currentItem else { return 0 }
        if playerItem.status == .readyToPlay {
            return CMTimeGetSeconds(playerItem.asset.duration)
        } else {
            return 0
        }
    }

    func changeIsShowControlView(_ isShowControlView: Bool, animated: Bool) {
        if !needShowControlView() {
            self.isShowControlView = false
        } else {
            self.isShowControlView = isShowControlView
        }

        let bottomViewNeedHidden = !self.isShowControlView
        let backButtonNeedHidden = !self.isShowControlView || !isFullscreen
        let playOrPauseBtn_CenterNeedHidden = !self.isShowControlView && !isPauseByUser
        let bottomProgressNeedHidden = self.isShowControlView

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.bottomView.alpha = bottomViewNeedHidden ? 0 : 1
                self.backButton.alpha = backButtonNeedHidden ? 0 : 1
                self.playOrPauseBtn_Center.alpha = playOrPauseBtn_CenterNeedHidden ? 0 : 1
                self.bottomProgress.alpha = bottomProgressNeedHidden ? 0 : 1
            }
        } else {
            bottomView.alpha = bottomViewNeedHidden ? 0 : 1
            backButton.alpha = backButtonNeedHidden ? 0 : 1
            playOrPauseBtn_Center.alpha = playOrPauseBtn_CenterNeedHidden ? 0 : 1
            bottomProgress.alpha = bottomProgressNeedHidden ? 0 : 1
        }

        if self.isShowControlView && !isDragingSlider {
            delayControlViewHide()
        }
    }

    func getFastForward() -> TimeInterval {
        var width: CGFloat = 0
        if isFullscreen {
            if videoSize.height >= videoSize.width {
                // 全屏竖屏
                width = frame.size.width
            } else {
                // 全屏横屏
                width = frame.size.height
            }
        } else {
            width = frame.size.width
        }

        // 计算滑动的x值,可以为负数,则回退
        let move_x = finalPoint.x - originalPoint.x
        // 快进的秒数
        let second = TimeInterval((move_x / width) * CGFloat(progressSlider.maximumValue))
        return second
    }

    @objc fileprivate func handleScrollGes(ges: UIPanGestureRecognizer) {
        print("\(ges.state)")

        let location = ges.location(in: self)
        guard let status = currentItem?.status else { return }
        switch ges.state {
        case .began:
            if !canDrag || !(status == AVPlayerItemStatus.readyToPlay) { return }
            // 记录下第一个点的位置
            bringSubview(toFront: forwardLabel)
            changeIsShowControlView(false, animated: true)
            originalPoint = location
            guard let player = player else { return }
            originalPlaySecond = CMTimeGetSeconds(player.currentTime())

        case .changed:
            if !canDrag || !(status == AVPlayerItemStatus.readyToPlay) { return }
            finalPoint = location
            // 判断是左右滑动还是上下滑动
            let verValue: CGFloat = fabs(originalPoint.y - finalPoint.y)
            let horValue: CGFloat = fabs(originalPoint.x - finalPoint.x)
            // 如果竖直方向的偏移量大于水平方向的偏移量,那么是调节音量或者亮度
            if verValue > horValue {
                // 上下滑动
            } else {
                // 左右滑动,调节视频的播放进度
                // 如果originalPoint=finalPoint,代表没有滑动,不显示forwardLabel
                forwardLabel.isHidden = originalPoint.equalTo(finalPoint)
                // 以屏幕宽度为基础,移动的X作为百分比
                let forwardSecond = getFastForward()
                print("快进: \(forwardSecond)秒")

                var gotoSecond = CGFloat(originalPlaySecond + forwardSecond)
                if gotoSecond < 0 {
                    gotoSecond = 0
                } else if gotoSecond > videoDuration {
                    gotoSecond = videoDuration
                }
                let forwardString = convertTime(second: gotoSecond)
                let allString = convertTime(second: videoDuration)
                forwardLabel.text = "\(forwardString)/\(allString)"
            }

        default:
            if !canDrag || !(status == AVPlayerItemStatus.readyToPlay) { return }
            if finalPoint.equalTo(CGPoint.zero) { return }
            forwardLabel.isHidden = true
            let forwardSecond = getFastForward()
            var gotoSecond = CGFloat(originalPlaySecond + forwardSecond)
            if gotoSecond >= videoDuration {
                moviePlayDidEnd(notification: nil)
            } else {
                if gotoSecond < 0 {
                    gotoSecond = 0
                }
                let dragedSeconds = floorf(Float(gotoSecond))
                setProgressValue(value: Double(dragedSeconds))
                seekToTime(time: Double(dragedSeconds))
            }
            originalPoint = .zero
            finalPoint = .zero
        }
    }

    @objc fileprivate func moviePlayDidEnd(notification: Notification?) {
        finishVideo()
    }

    fileprivate func cancelControlViewHide() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControlView), object: nil)
    }

    fileprivate func delayControlViewHide() {
        if isShowControlView {
            cancelControlViewHide()
            perform(#selector(hideControlView), with: nil, afterDelay: 3)
        }
    }

    @objc fileprivate func hideControlView() {
        UIView.animate(withDuration: 0.2) {
            self.changeIsShowControlView(false, animated: true)
        }
    }
}

extension WMPlayer: UIGestureRecognizerDelegate {

}

class WMPlayerLoadingView: UIView {

    fileprivate var animatingView = UIView()

    func startAnimating() {
        isHidden = false
        guard let superview = superview else { return }
        center = CGPoint(x: superview.bounds.size.width/2, y: superview.bounds.size.height/2)
        if animatingView.layer.animation(forKey: "rotationAnimation") == nil {
            addAnimation()
        }
    }

    func stopAnimating() {
        animatingView.layer.removeAllAnimations()
        isHidden = true
    }

    fileprivate func addAnimation() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = 1
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = 10000
        animatingView.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let image = UIImage(named: "icon_video_loading")
        let imgView = UIImageView(image: image)
        addSubview(imgView)

        backgroundColor = UIColor.clear
        animatingView = imgView
        addAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        animatingView.frame = bounds
    }
}

class WMProxyScrollView: UIScrollView, UIGestureRecognizerDelegate {
    var gesEnabled: Bool?
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        guard gesEnabled != nil || gesEnabled == true else { return false }
        if bounds.contains(point) {
            return true
        }
        return false

    }
}
