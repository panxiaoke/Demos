//
//  BLPlayerViewController.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/18.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit
import AVFoundation

enum VideoPlayState: Int {
    case unknown
    case playing
    case puase
    case end
}

fileprivate extension Selector {
    // 点击事件
    static let handleCloseSEL = #selector(PlayerViewController.handleClose(sender:))
    static let handleControlSEL = #selector(PlayerViewController.handleControl(sender:))
    static let handleChangeSliderSEL = #selector(PlayerViewController.handleChangeSlider(sender:))
    static let handleSingleTapSEL = #selector(PlayerViewController.handleSingleTap(gesture:))
    static let handleCenterPlaySEL = #selector(PlayerViewController.handleCenterPlay(sender:))
    
    // 通知处理
    static let handlePlayerEndPlayingSEL = #selector(PlayerViewController.handlePlayerEndPlaying(notification:))
    static let handleAppDidEnterBackgroundSEL = #selector(PlayerViewController.handleAppDidEnterBackground(notification:))
}

@objcMembers class PlayerViewController: FXViewController {
    
    // 播放器模型，包含了视屏的相关信息
    var playerModel: PlayerModel = PlayerModel()
    
    // 视频播放状态
    var playState: VideoPlayState = .unknown {
        didSet {
            switch playState {
            case .playing:
                self.controlBtn.isSelected = false
                self.centerPlayBtn.isHidden = true
            case .puase, .end:
                self.controlBtn.isSelected = true
                self.centerPlayBtn.isHidden = false
            default:
                print("其他状态")
            }
        }
        
    }
    
    fileprivate var player: AVPlayer?
    fileprivate var playerItem: AVPlayerItem?
    fileprivate var playerView: PlayerView!
    // 点击隐藏一些视图
    fileprivate var isHiddenSomeViews = true {
        didSet {
            self.closeBtn.isHidden = isHiddenSomeViews
            self.controlBtn.isHidden = isHiddenSomeViews
            self.playedDurationLabel.isHidden = isHiddenSomeViews
            self.progressSlider.isHidden = isHiddenSomeViews
            self.videoDurationLabel.isHidden = isHiddenSomeViews
        }
    }
    
    fileprivate var timeObserverToken: Any?
    
    // 视频时长，单位：秒
    fileprivate var videoDuration: Int = 0 {
        didSet {
            let durationStr = self.formateVideoDuration(duration: videoDuration)
            self.videoDurationLabel.text = durationStr
        }
    }
    
    // 关闭按钮
    lazy var closeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: Selector.handleCloseSEL, for: .touchUpInside)
        let y = UIDevice.iPhoneX() ? 20 : 0
        btn.frame = CGRect(x: 0, y: y, width: 64, height: 64)
        btn.setImage(UIImage(named: "chat_player_close"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.isHidden = isHiddenSomeViews
        return btn
    }()
    
    // 播放/暂停按钮
    lazy var controlBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: Selector.handleControlSEL, for: .touchUpInside)
        let bottomSafeDistance: CGFloat = UIDevice.iPhoneX() ? 34 : 0
        btn.frame = CGRect(x: 0, y: self.view.frame.height - 64 - bottomSafeDistance, width: 64, height: 64)
        btn.setImage(UIImage(named: "chat_player_pause"), for: .normal)
        btn.setImage(UIImage(named: "chat_player_play"), for: .selected)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.isHidden = isHiddenSomeViews
        return btn
    }()
    
    // 进度条
    lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0.0
        slider.minimumValue = 0.0
        slider.maximumValue = Float(self.playerModel.duration);
        slider.minimumTrackTintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
        slider.maximumTrackTintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2)
        slider.setThumbImage(UIImage(named: "chat_player_dot"), for: .normal)
        slider.setThumbImage(UIImage(named: "chat_player_dot"), for: .highlighted)
        slider.addTarget(self, action: Selector.handleChangeSliderSEL, for: UIControl.Event.valueChanged)
        slider.isHidden = isHiddenSomeViews;
        return slider
    }()
    
    // 当前播放时长
    lazy var playedDurationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "00:00"
        label.isHidden = isHiddenSomeViews
        return label
    }()
    
    // 视频总时长
    lazy var videoDurationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "00:00"
        label.isHidden = isHiddenSomeViews
        return label
    }()

    // 中心部分的播放按钮
    lazy var centerPlayBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "chat_player_centerplay"), for: .normal)
        btn.titleLabel?.textColor = .white
        btn.addTarget(self, action: Selector.handleCenterPlaySEL, for: .touchUpInside)
        btn.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
        btn.center = CGPoint(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
        btn.isHidden = true
        return btn
    }()
    
    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.view.bounds;
        imageView.backgroundColor = .black
        imageView.center = CGPoint(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var loadingActivity: ZFLoadingView = {
        let activity = ZFLoadingView()
        activity.hidesWhenStopped = true
        activity.lineColor = .white
        activity.animType = .fadeOut
        activity.frame = CGRect(x: self.view.frame.width * 0.5 - 32, y: self.view.frame.height * 0.5 - 32, width: 64, height: 64)
        return activity
    }()
    
    init(model: PlayerModel) {
        playerModel = model
       
        super.init(nibName: nil, bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("testdata----释放了")
        self.removeListeners()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        self.addGestures()
        self.setupPlayer()
        self.setupUI()
        self.addListeners()
        videoDuration = self.playerModel.duration
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bottomSafeDistance: CGFloat = UIDevice.iPhoneX() ? 34 : 0
        let controlBtnCenterY = self.controlBtn.frame.minY + self.controlBtn.frame.height * 0.5 - bottomSafeDistance
        let margin: CGFloat = 5
        let labelWidth: CGFloat = 35
        let height: CGFloat = 44
        
        self.controlBtn.center = CGPoint(x: self.controlBtn.center.x, y: controlBtnCenterY)
        
        let palyedDruationLabelX = self.controlBtn.frame.maxX + margin
        self.playedDurationLabel.frame = CGRect(x: palyedDruationLabelX, y: controlBtnCenterY, width: labelWidth, height: height)
        self.playedDurationLabel.center = CGPoint(x: self.playedDurationLabel.center.x, y: controlBtnCenterY)
        
        let progressSliderX = self.playedDurationLabel.frame.maxX + margin
        var progressSliderWidth: CGFloat = self.view.frame.width - self.controlBtn.frame.maxX - labelWidth * 2 - margin * 2
        progressSliderWidth -= 20
        self.progressSlider.frame = CGRect(x: progressSliderX, y: controlBtnCenterY, width: progressSliderWidth, height: height)
        self.progressSlider.center = CGPoint(x: self.progressSlider.center.x, y: controlBtnCenterY)
        
        let videoDurationLabelX = self.progressSlider.frame.maxX + margin
        self.videoDurationLabel.frame = CGRect(x: videoDurationLabelX, y: controlBtnCenterY, width: labelWidth, height: height)
        self.videoDurationLabel.center = CGPoint(x: self.videoDurationLabel.center.x, y: controlBtnCenterY)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.setStatusBarHidden(true, with: .fade)
        if !self.coverImageView.isHidden {
            self.loadingActivity.startAnimating()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .fade)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.replaceCurrentItem(with: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
            
        } else if keyPath == "status" {
            if playerItem?.status == AVPlayerItem.Status.readyToPlay {
                if playerModel.autoPlay {
                    self.play()
                }
            } else if (playerItem?.status == .failed) {
                print("播放视频失败=", playerItem?.error ?? "1")
            }
        }
    }
}

// MARK: - Assit
fileprivate extension PlayerViewController {
    
    // UI
    func setupUI() {
        if self.playerModel.coverImageURL != nil {
             self.view.addSubview(self.coverImageView)
             self.coverImageView.sd_setImage(with: self.playerModel.coverImageURL, placeholderImage: self.playerModel.coverPlaceolderImage, options: .retryFailed, progress: nil, completed: nil)
        }
        
        let color0 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        // 顶部的渐变图层
        let topBackgroundLayer = CAGradientLayer()
        topBackgroundLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.closeBtn.frame.maxY)
        topBackgroundLayer.colors = [color0, color1]
        topBackgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        topBackgroundLayer.endPoint = CGPoint(x: 0, y: 1)
        self.view.layer.addSublayer(topBackgroundLayer)
        // 底部的渐变图层
        let bottomSafeDistance: CGFloat = UIDevice.iPhoneX() ? 34 : 0
        let bottomBackgroundLayerY = self.view.frame.height - 64 - bottomSafeDistance
        let bottomBackgroudLayer = CAGradientLayer()
        bottomBackgroudLayer.frame = CGRect(x: 0, y: bottomBackgroundLayerY, width: self.view.frame.width, height: self.closeBtn.frame.maxY)
        bottomBackgroudLayer.colors = [color0, color1]
        bottomBackgroudLayer.startPoint = CGPoint(x: 0, y: 1)
        bottomBackgroudLayer.endPoint = CGPoint(x: 0, y: 0)
        self.view.layer.addSublayer(bottomBackgroudLayer)
        
        
        self.view.addSubview(self.closeBtn)
        self.view.addSubview(self.centerPlayBtn)
        self.view.addSubview(self.controlBtn)
        self.view.addSubview(self.progressSlider)
        self.view.addSubview(self.playedDurationLabel)
        self.view.addSubview(self.videoDurationLabel)
        self.view.addSubview(self.loadingActivity)
    }
    
    
    /// 初始化播放器
    func setupPlayer() {
        
        playerItem = AVPlayerItem(url: self.playerModel.videoURL)
        
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = playerModel.isMuted
        
        playerView = PlayerView()
        playerView.backgroundColor = .black
        playerView.player = player
        
        self.view.addSubview(playerView)
        playerView.frame = self.view.bounds
       
    }
    
    /// 添加观察者
    func addListeners() {
        NotificationCenter.default.addObserver(self, selector: Selector.handlePlayerEndPlayingSEL, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector.handleAppDidEnterBackgroundSEL, name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // 播放状态与缓冲
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        // 播放进度
        let interval = CMTime(seconds: 0.1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: {[weak self] (time) in
            if let strongSelf = self {
                let current = CMTimeGetSeconds(time)
                if current > 0 && !strongSelf.coverImageView.isHidden {
                    UIView.animate(withDuration: 0.05, animations: {
                        strongSelf.coverImageView.alpha = 0
                    }, completion: { (finished) in
                        strongSelf.coverImageView.isHidden = true
                        strongSelf.coverImageView.alpha = 1
                    })
                   
                    strongSelf.loadingActivity.stopAnimating()
                }
                strongSelf.playedDurationLabel.text = strongSelf.formateVideoDuration(duration: Int(current))
                if let durtion = strongSelf.player?.currentItem?.duration {
                    let total = CMTimeGetSeconds(durtion)
                    if  0 == strongSelf.videoDuration && total <= Double(Int.max){
                        strongSelf.videoDuration = Int(total)
                        strongSelf.progressSlider.maximumValue = Float(total)
                    }
                }
                strongSelf.progressSlider.value = Float(current)
            }
        })
    }
    
    /// 移除观察者
    func removeListeners() {
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "status")
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    /// 添加手势
    func addGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector.handleSingleTapSEL)
        self.view.addGestureRecognizer(tapGesture)
    }
    
    
    /// 格式化视屏时长
    ///
    /// - Parameter duration: 视屏时长
    /// - Returns: 视屏时长字符串
    func formateVideoDuration(duration: Int) -> String {
        var mutableDuration = duration
        let perMinuteSeconds = 60
        let minutes = mutableDuration / perMinuteSeconds
        mutableDuration -= minutes * perMinuteSeconds
        let seconds = mutableDuration
        return String(format: "%02ld:%02ld", minutes, seconds)
    }
    
    /// 设置视频的播放时间
    func seekToTime(seconds: TimeInterval, completionHandler: @escaping(Bool) -> ()) {
        let seekTime = CMTime(seconds: seconds, preferredTimescale: 1)
        playerItem?.cancelPendingSeeks()
        player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completionHandler)
    }
    
    /// 通过当前状态，判断播放，或者暂停
    func playerPlayOrPause() {
        switch self.playState {
        case .unknown, .puase:
            self.play()
        case .playing:
            self.pause()
        case .end:
            self.replay()
        }
    }
}

// MARK: - Click Event
fileprivate extension PlayerViewController {

    /// 关闭页面
    @objc func handleClose(sender: UIButton) {
        self.player = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    // 点击视图中心的播放按钮
    @objc func handleCenterPlay(sender: UIButton) {
        self.playerPlayOrPause()
    }
    
    /// 播放器播放器暂停
    @objc func handleControl(sender: UIButton) {
        self.playerPlayOrPause()
    }
    
    /// 拖动进度条
    @objc func handleChangeSlider(sender: UISlider) {
        if player?.status == AVPlayer.Status.readyToPlay {
            let duration = sender.value / sender.maximumValue * Float(self.videoDuration)
            self.seekToTime(seconds: Double(duration)) { (finished) in
                
            }
        }
    }
    
    /// 点击事件
    @objc func handleSingleTap(gesture: UIGestureRecognizer) {
        isHiddenSomeViews = !isHiddenSomeViews
    }
}

// MARK: - 通知处理/KVO
fileprivate extension PlayerViewController {
    
    @objc func handlePlayerEndPlaying(notification: Notification) {
        self.playState = .end
        self.isHiddenSomeViews = false
    }
    
    @objc func handleAppDidEnterBackground(notification: Notification) {
        self.pause()
    }
    
}

// MARK: - 公有方法
extension PlayerViewController {
    func play() {
        if self.playState == .unknown  || self.playState == .puase {
            player?.play()
        }
        self.playState = .playing
    }
    
    func replay() {
        self.seekToTime(seconds: 0) { [weak self] (finished) in
            self?.playState = .unknown
            self?.play()
        }
    }
    
    func pause() {
        player?.pause()
        self.playState = .puase
    }

}
