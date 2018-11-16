//
//  KFCPlayer.swift
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
    static let handleCloseSEL = #selector(KFCPlayer.handleClose(sender:))
    static let handleControlSEL = #selector(KFCPlayer.handleControl(sender:))
    static let handleChangeSliderSEL = #selector(KFCPlayer.handleChangeSlider(sender:))
    static let handleSingleTapSEL = #selector(KFCPlayer.handleSingleTap(gesture:))
    static let handleCenterPlaySEL = #selector(KFCPlayer.handleCenterPlay(sender:))
    
    // 通知处理
    static let handlePlayerEndPlayingSEL = #selector(KFCPlayer.handlePlayerEndPlaying(notification:))
    static let handleAppResignActiveSEL = #selector(KFCPlayer.handleAppResignActive(notification:))
}

@objcMembers class KFCPlayer: UIView {
    
    // 播放器模型，包含了视屏的相关信息
    var playerModel: PlayerModel = PlayerModel()
    
    /// 顶部的安全距离
    fileprivate var topSafeDistance: CGFloat {
        if #available(iOS 11, *) {
            return 20
        }
        return 0
    }
    
    /// 底部的安全距离
    fileprivate var bottomSafeDistance: CGFloat {
        if #available(iOS 11, *) {
            return 34
        }
        return 0
    }
    
    // 视频播放状态
    fileprivate var playState: VideoPlayState = .unknown {
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
    
    fileprivate var isUnSupport = false
    
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
        btn.frame = CGRect(x: 0, y: self.frame.height - 64 - bottomSafeDistance, width: 64, height: 64)
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
        btn.center = CGPoint(x: self.frame.width * 0.5, y: self.frame.height * 0.5)
        btn.isHidden = true
        return btn
    }()
    
    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds;
        imageView.backgroundColor = .black
        imageView.center = CGPoint(x: self.frame.width * 0.5, y: self.frame.height * 0.5)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var loadingActivity: ZFLoadingView = {
        let activity = ZFLoadingView()
        activity.hidesWhenStopped = true
        activity.lineColor = .white
        activity.animType = .fadeOut
        activity.frame = CGRect(x: self.frame.width * 0.5 - 32, y: self.frame.height * 0.5 - 32, width: 64, height: 64)
        return activity
    }()
    
    lazy var unSupportHintView: UnSupportVideoHintView = {
        let hintView = UnSupportVideoHintView()
        hintView.isHidden = true
        return hintView
    }()
    
    init(model: PlayerModel) {
        playerModel = model
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black
        self.addGestures()
        self.setupPlayer()
        self.setupUI()
        self.addListeners()
        videoDuration = self.playerModel.duration
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeListeners()
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        UIApplication.shared.setStatusBarHidden(true, with: .fade)
//        if !self.coverImageView.isHidden {
//            self.loadingActivity.startAnimating()
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        UIApplication.shared.setStatusBarHidden(false, with: .fade)
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        self.cancelWaiting()
//    }
//
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
            
        } else if keyPath == "status" {
            if playerItem?.status == AVPlayerItem.Status.readyToPlay {
                if playerModel.autoPlay {
                    self.playWithReadyState()

                }
            } else if (playerItem?.status == .failed) {
                if (playerItem?.error) != nil {
                    let isLocal = self.isLocalVideo()
                    if isLocal {
                        self.showInvalidVideoHintView()
                    } else {
                        if let source = self.playerModel.sourcePath, let target = self.playerModel.targetPath {
                        }
                        
                    }
                    
                }
            }
        }
    }
}

// MARK: - Assit
fileprivate extension KFCPlayer {
    
    // UI
    func setupUI() {
        if self.playerModel.coverImageURL != nil {
             self.addSubview(self.coverImageView)
             self.coverImageView.sd_setImage(with: self.playerModel.coverImageURL, placeholderImage: self.playerModel.coverPlaceolderImage, options: .retryFailed, progress: nil, completed: nil)
        }
        
//        let color0 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
//        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
//        // 顶部的渐变图层
//        let topBackgroundLayer = CAGradientLayer()
//        topBackgroundLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.closeBtn.frame.maxY)
//        topBackgroundLayer.colors = [color0, color1]
//        topBackgroundLayer.startPoint = CGPoint(x: 0, y: 0)
//        topBackgroundLayer.endPoint = CGPoint(x: 0, y: 1)
//        self.layer.addSublayer(topBackgroundLayer)
//        // 底部的渐变图层
//        let bottomSafeDistance: CGFloat = UIDevice.iPhoneX() ? 34 : 0
//        let bottomBackgroundLayerY = self.frame.height - 64 - bottomSafeDistance
//        let bottomBackgroudLayer = CAGradientLayer()
//        bottomBackgroudLayer.frame = CGRect(x: 0, y: bottomBackgroundLayerY, width: self.frame.width, height: self.closeBtn.frame.maxY)
//        bottomBackgroudLayer.colors = [color0, color1]
//        bottomBackgroudLayer.startPoint = CGPoint(x: 0, y: 1)
//        bottomBackgroudLayer.endPoint = CGPoint(x: 0, y: 0)
//        self.layer.addSublayer(bottomBackgroudLayer)
        
        
        self.addSubview(self.closeBtn)
        closeBtn.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(topSafeDistance)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        self.addSubview(self.centerPlayBtn)
        centerPlayBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        self.addSubview(self.controlBtn)
        controlBtn.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(-bottomSafeDistance)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
       
        self.addSubview(self.playedDurationLabel)
        self.playedDurationLabel.snp.makeConstraints { (make) in
            make.left.equalTo(controlBtn.snp.right).offset(10)
            make.centerY.equalTo(controlBtn)
            make.width.equalTo(30)
        }
        
        self.addSubview(self.videoDurationLabel)
        self.videoDurationLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-28)
            make.centerY.equalTo(controlBtn)
            make.width.equalTo(30)
        }
        
        self.addSubview(self.progressSlider)
        self.progressSlider.snp.makeConstraints { (make) in
            make.left.equalTo(playedDurationLabel.snp.right).offset(8)
            make.centerY.equalTo(playedDurationLabel)
            make.right.equalTo(videoDurationLabel.snp.left).offset(-8)
        }
        
       
        self.addSubview(self.loadingActivity)
        self.loadingActivity.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
        }
        
        self.addSubview(self.unSupportHintView)
        self.unSupportHintView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    func showInvalidVideoHintView() {
        self.coverImageView.isHidden = true
        self.loadingActivity.stopAnimating()
        self.unSupportHintView.isHidden = false
        self.closeBtn.isHidden = false
        self.isUnSupport = true
    }
    
    func isLocalVideo() -> Bool {
        if let target = self.playerModel.targetPath {
          return self.playerModel.isLocal ||  FileManager.default.fileExists(atPath: target)
        }
        return self.playerModel.isLocal
    }
    
    
    /// 初始化播放器
    func setupPlayer() {
        let asset = AVAsset(url: self.playerModel.videoURL)
        playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = playerModel.isMuted
        player?.actionAtItemEnd = .pause
        // 播放进度
        let interval = CMTime(seconds: 0.1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: {[weak self] (time) in
            if let strongSelf = self {
                let current = CMTimeGetSeconds(time)
                if current > 0 && !strongSelf.coverImageView.isHidden {
                    strongSelf.coverImageView.isHidden = true
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
        
        playerView = PlayerView()
        playerView.backgroundColor = .black
        playerView.player = player
        
        self.addSubview(playerView)
        playerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
       
    }
    
    /// 添加观察者
    func addListeners() {
        self.addListenersForPlayerCurrentItem()
        NotificationCenter.default.addObserver(self, selector: Selector.handlePlayerEndPlayingSEL, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector.handleAppResignActiveSEL, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    /// 移除观察者
    func removeListeners() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        self.removeListenersForPlayerCurrentItem()
    }
    
    // 添加AVPlayerItem的观察者
    func addListenersForPlayerCurrentItem() {
        let currentPlayerItem = self.player?.currentItem
        // 播放状态与缓冲
        currentPlayerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        currentPlayerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
    }
    
    func removeListenersForPlayerCurrentItem() {
        let currentPlayerItem = self.player?.currentItem
        currentPlayerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        currentPlayerItem?.removeObserver(self, forKeyPath: "status")
    }
    
    /// 添加手势
    func addGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector.handleSingleTapSEL)
        self.addGestureRecognizer(tapGesture)
    }
    
    /// 取消等待
    func cancelWaiting() {
        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()
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
            self.playWithReadyState()
        case .playing:
            self.pause()
        case .end:
            self.replay()
        }
    }
}

// MARK: - Click Event
fileprivate extension KFCPlayer {

    /// 关闭页面
    @objc func handleClose(sender: UIButton) {
//        self.dismiss(animated: true, completion: nil)
        self.dismiss()
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
        if self.isUnSupport {
//            self.dismiss(animated: true, completion: nil)
        } else {
            isHiddenSomeViews = !isHiddenSomeViews
        }
    }
}

// MARK: - 通知处理/KVO
fileprivate extension KFCPlayer {
    
    @objc func handlePlayerEndPlaying(notification: Notification) {
        self.playState = .end
        self.isHiddenSomeViews = false
    }
    
    @objc func handleAppResignActive(notification: Notification) {
        self.pause()
    }
}

extension KFCPlayer {
    func playWithReadyState() {
        if self.playState == .unknown  || self.playState == .puase {
            player?.play()
            self.playState = .playing
        }
    }
    
    func playerWithErrorState() {
        if let target = self.playerModel.targetPath {
            // 释放旧的视频资源
            self.cancelWaiting()
            self.removeListenersForPlayerCurrentItem()
            self.playState = .unknown
            // 加载新的视频资源
            let url = URL(fileURLWithPath: target)
            let asset = AVAsset(url: url)
            playerItem = AVPlayerItem(asset: asset)
            self.player?.replaceCurrentItem(with: playerItem)
            self.addListenersForPlayerCurrentItem()
            self.playWithReadyState()
        }
    }
    
    func replay() {
        self.seekToTime(seconds: 0) { [weak self] (finished) in
            self?.playState = .unknown
            self?.playWithReadyState()
        }
    }
    
    func pause() {
        if self.playState == .playing {
            player?.pause()
            self.playState = .puase
        }
    }

}

extension KFCPlayer {
    func show(from view: UIView?) {
        if let keyWindow = UIApplication.shared.delegate?.window {
            self.frame = keyWindow!.bounds
            keyWindow?.addSubview(self)
            self.playWithReadyState()
            playerView.frame = self.bounds
        }
    }
    
    func dismiss() {
        self.removeFromSuperview()
    }
}
