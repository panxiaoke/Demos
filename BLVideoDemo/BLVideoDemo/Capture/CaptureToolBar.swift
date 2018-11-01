//
//  CaptureToolBar.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/13.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit

fileprivate extension Selector {
    static let handleDismissSEL = #selector(CaptureToolBar.hendleDismiss(sender:))
    static let handleTapRecordViewSEL = #selector(CaptureToolBar.handleTapRecordView(gesture:))
    static let handleLongPressRecordViewSEL = #selector(CaptureToolBar.handleLongPressRecordView(gesture:))
    static let handleCompleteSEL = #selector(CaptureToolBar.handleComplete(sender:))
    static let handleGiveUpSEL = #selector(CaptureToolBar.handleGiveUp(sender:))
}


enum BLCaptureToolBarState: Int {
    case unknown
    case capturing
    case end
}

enum BLCaptureToolBarActionType: Int{
    case dismiss
    case takePhoto
    case startRecordVideo
    case stopRecordVideo
    case giveUp
    case use
}

typealias BLCaptureToolBarActionHandler = (_ : BLCaptureToolBarActionType) -> Void

class CaptureToolBar: UIView {
    
    var state: BLCaptureToolBarState
    var handler: BLCaptureToolBarActionHandler?
    
    lazy var dismissBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.setImage(R.image.chat_capture_dimiss(), for: .normal)
        btn.addTarget(self, action: Selector.handleDismissSEL, for: .touchUpInside)
        return btn
    }()
    
    lazy var completeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .white
        btn.setImage(R.image.capture_result_use(), for: .normal)
        btn.addTarget(self, action: Selector.handleCompleteSEL, for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    lazy var giveUpBtnBackgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.isHidden = true
        return view
    }()
    
    lazy var giveUpBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor(white: 1, alpha: 0.2)
        btn.setImage(R.image.capture_result_giveup(), for: .normal)
        btn.addTarget(self, action: Selector.handleGiveUpSEL, for: .touchUpInside)
        return btn
    }()
    
    lazy var recordView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    lazy var progressView: CaptureProgressView = {
        let view = CaptureProgressView()
        return view
    }()
    
    
    // MARK: LifeCircle
    init(frame: CGRect, state: BLCaptureToolBarState = .unknown) {
        self.state = state
        super.init(frame: frame)
        self.setupUI()
        self.addGestureToRecordView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.frame.width
        self.dismissBtn.frame = CGRect(x: 62.5, y: 0, width: 55, height: 55)
        self.dismissBtn.center = CGPoint(x: self.dismissBtn.center.x, y: self.frame.height * 0.5)
        
        self.recordView.frame = CGRect(x: width * 0.5, y: 0, width: 55, height: 55)
        self.recordView.center = CGPoint(x: self.frame.width * 0.5, y: self.frame.height * 0.5)
        self.recordView.layer.cornerRadius = self.recordView.frame.width * 0.5
        
        self.progressView.frame = CGRect(x: width * 0.5, y: 0, width: 75, height: 75)
        self.progressView.center = CGPoint(x: self.frame.width * 0.5 , y: self.frame.height * 0.5)
        
        self.giveUpBtnBackgroundView.frame = CGRect(x: width * 0.1, y: 0, width: 75, height: 75)
        self.giveUpBtnBackgroundView.center = CGPoint(x: self.giveUpBtnBackgroundView.center.x, y: self.frame.height * 0.5)
        self.giveUpBtnBackgroundView.layer.cornerRadius = self.giveUpBtnBackgroundView.frame.width * 0.5
        self.giveUpBtnBackgroundView.layer.masksToBounds = true
        
        self.giveUpBtn.frame = self.giveUpBtnBackgroundView.bounds
        self.giveUpBtn.layer.cornerRadius = self.giveUpBtnBackgroundView.bounds.width * 0.5
        self.giveUpBtn.layer.masksToBounds = true
        
        self.completeBtn.frame = CGRect(x: width - width * 0.1 - 75, y: 0, width: 75, height: 75)
        self.completeBtn.center = CGPoint(x: self.completeBtn.center.x, y: self.frame.height * 0.5)
        self.completeBtn.layer.cornerRadius = self.completeBtn.frame.width * 0.5
        self.completeBtn.layer.masksToBounds = true
    }
    
}

// MARK: - Assist
fileprivate extension CaptureToolBar {
    
    func setupUI() {
        self.addSubview(self.dismissBtn)
        self.addSubview(self.recordView)
        self.insertSubview(self.progressView, belowSubview: self.recordView)
        self.addSubview(self.giveUpBtnBackgroundView)
        self.giveUpBtnBackgroundView.contentView.addSubview(self.giveUpBtn)
        
        self.addSubview(self.completeBtn)
    }
    
    func addGestureToRecordView() {
        // 点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector.handleTapRecordViewSEL)
        self.recordView.addGestureRecognizer(tapGesture)
        
        // 长按手势
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector.handleLongPressRecordViewSEL)
        longPressGesture.minimumPressDuration = 0.5
        tapGesture.require(toFail: longPressGesture)
        self.recordView.addGestureRecognizer(longPressGesture)
    }
    
    func zoomRcordView() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 55 / 40
        animation.duration = 0.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        self.recordView.layer.add(animation, forKey: "ani")
    }
    
    func resetRecordView() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1
        animation.duration = 0.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        self.recordView.layer.add(animation, forKey: "ani")
    }
    
    func update(state: BLCaptureToolBarState) {
        self.state = state
        switch state {
        case .end:
            self.captureActionEnd()
        case .capturing:
            self.dismissBtn.isHidden = true;
        default:
            print("其他动作")
        }
    }
}

// MARK: - Click Event
fileprivate extension CaptureToolBar {
    
    @objc func hendleDismiss(sender: UIButton) {
        self.handler?(.dismiss)
    }
    
    @objc func handleTapRecordView(gesture: UITapGestureRecognizer) {
        self.update(state: .end)
        self.handler?(.takePhoto)
    }
    
    @objc func handleLongPressRecordView(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            if state == .unknown {
                self.update(state: .capturing)
                self.handler?(.startRecordVideo)
            }
        case .ended, .cancelled:
            if (self.state == .capturing) {
                self.update(state: .end)
                self.handler?(.stopRecordVideo)
            }
        default:
            print("其他手势")
        }
    }
    
    @objc func handleComplete(sender: UIButton) {
        self.handler?(.use)
    }
    
    @objc func handleGiveUp(sender: UIButton) {
        self.completeBtn.isHidden = true
        self.giveUpBtnBackgroundView.isHidden = true
        
        self.progressView.progress = 0;
        self.dismissBtn.isHidden = false
        self.recordView.isHidden = false
        self.progressView.isHidden = false
        self.update(state: .unknown)
        self.handler?(.giveUp)
    }
}

// MARK: - Public
extension CaptureToolBar {
    
    /// 开始录制，进度条开始
    func startRecordProgress() {
        self.zoomRcordView()
        self.progressView.start()
    }
    
    /// 更新进度条进度
    ///
    /// - Parameter progress: 当前进度
    func updateProgress(progress: Double) {
        self.progressView.progress = progress
    }
    
    /// 结束录制
    func finishCaptureProgress() {
        self.giveUpBtnBackgroundView.isHidden = false
        self.completeBtn.isHidden = false
        
        let giveUpBtnAniamtion = CABasicAnimation(keyPath: "position.x")
        giveUpBtnAniamtion.duration = 0.15
        giveUpBtnAniamtion.fromValue = self.frame.width * 0.5
        self.giveUpBtnBackgroundView.layer.add(giveUpBtnAniamtion, forKey: "aniForGiveUpBtn")
        
        let completeBtnAnimation = CABasicAnimation(keyPath: "position.x")
        completeBtnAnimation.duration = 0.15
        completeBtnAnimation.fromValue = self.frame.width * 0.5
        self.completeBtn.layer.add(completeBtnAnimation, forKey: "aniForCompleteBtn")
    }
    
    func captureActionEnd() {
        self.dismissBtn.isHidden = true
        self.recordView.isHidden = true
        self.progressView.isHidden = true
        self.progressView.reset()
        self.resetRecordView()
    }
}


