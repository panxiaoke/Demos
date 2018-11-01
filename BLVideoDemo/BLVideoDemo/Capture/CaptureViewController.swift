//
//  CaptureViewController.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/13.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreMotion

fileprivate extension Selector {
    static let handleChangeCameraSEL = #selector(CaptureViewController.handleChangeCamera(sender:))
    static let handleSingleTapSEL = #selector(CaptureViewController.handleSigleTap(sender:))
    static let handleDoubleTapSEL = #selector(CaptureViewController.handleDoubleTap(sender:))
    static let handlePinchSEL = #selector(CaptureViewController.handlePinch(sender:))
}

@objc protocol CaptureViewControllerDelegate: AnyObject {
    func captureViewController(vc: CaptureViewController, didFinishRecordVideo videoURL: URL, error: Error?)
    func captureViewController(vc: CaptureViewController, didFinishTakePhoto photoData: Data?, error: Error?)
}

fileprivate enum OutputFileType: Int {
    case image
    case video
}

@objc class CaptureViewController: UIViewController {
    
    @objc var maxRecordTime: Int = 15
    @objc weak var delegate: CaptureViewControllerDelegate?
    
    fileprivate var imageCaptureDevice: AVCaptureDevice?
    fileprivate var videoInput: AVCaptureDeviceInput!
    fileprivate var movieOutput: AVCaptureMovieFileOutput!
    fileprivate var photoOutput: AVCaptureStillImageOutput!
    fileprivate var audioDevice: AVCaptureDevice!
    fileprivate var audioInput: AVCaptureDeviceInput!
    fileprivate var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!
    fileprivate var outputFileType: OutputFileType = .image
    fileprivate var photoData: Data?
    fileprivate var timer: DispatchSourceTimer?
    fileprivate var deviceOrientation: UIDeviceOrientation = .portrait
    
    fileprivate var videoURL: URL?
    
    var lastScale: CGFloat = 1.0
    var effectiveScale: CGFloat = 1.0
    
    lazy var playerView: PlayerView = {
        let view = PlayerView()
        view.backgroundColor = UIColor.black
        return view
    }()
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    
    fileprivate lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        // 默认图片
        if session.canSetSessionPreset(AVCaptureSession.Preset.photo) {
            session.canSetSessionPreset(AVCaptureSession.Preset.photo)
        }
        return session
    }()
    
    fileprivate lazy var motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.accelerometerUpdateInterval = 0.45
        return manager
    }()
    
    lazy var previewContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.frame = self.view.bounds;
        return view
    }()

    fileprivate lazy var toolBar: CaptureToolBar = {
        let toolBarHeight: CGFloat = UIDevice.iPhoneX() ? 280 : 160
        let origin = CGPoint(x: 0, y: self.view.frame.size.height - toolBarHeight)
        let size = CGSize(width: self.view.frame.size.width, height: toolBarHeight)
        let view = CaptureToolBar(frame: CGRect(origin: origin, size: size), state: .unknown)
        view.handler = { [weak self] (type) -> Void in
            self?.handleToolBarAction(type: type)
        }
        return view
    }()
    
    fileprivate lazy var photoImageView: UIImageView = {
        let imageView = UIImageView(frame: self.view.bounds)
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    fileprivate lazy var changeCameraBtn: UIButton = {
        let btn = UIButton(type: .custom)
        let btnY: CGFloat = UIDevice.iPhoneX() ? 34 : 20
        btn.frame = CGRect(x: self.view.frame.width - 64, y: 20, width: 64, height: 64)
        btn.setImage(R.image.camera_change_nor(), for: .normal)
        btn.setImage(R.image.camera_change_lighted(), for: .highlighted)
        btn.addTarget(self, action: Selector.handleChangeCameraSEL, for: .touchUpInside)
        return btn
    }()
    
    lazy var focusIndicator: CaptureFocusIndicator = {
        let indicator = CaptureFocusIndicator()
        indicator.frame = CGRect(x:0, y: 0, width: 100, height: 100)
        indicator.center = CGPoint(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
        indicator.backgroundColor = .clear
        indicator.isHidden = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.checkAuthorization()
        self.setupCaptureSetting()
        self.startAccelerometerUpdates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.setStatusBarHidden(true, with: .fade)
        let canCapture = self.canCapture()
        if canCapture {
            self.setAutoFocus()
            self.showAccessHintView()
            self.showOperationHint()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .fade)
    }
    
    deinit {
        self.stopAccelerometerUpdates()
    }
    
    func setupCaptureSetting() {
        let canAccessVideo = self.canAccessVideoDevice()
        let canAccessAudio = self.canAccessAudioDevice()
        if canAccessVideo {
            self.configCaptureSession()
            self.addGestureRecognizers()
        }
        
        if canAccessVideo && canAccessAudio {
             self.view.isUserInteractionEnabled = true
        } else {
           self.view.isUserInteractionEnabled = false
        }
    }
}

// MARK: - Assist
extension CaptureViewController {
    // MARK: - UI
    func setupUI() {
        self.view.backgroundColor = .black
        self.view.addSubview(self.previewContainerView)
        self.view.addSubview(self.toolBar)
        self.view.insertSubview(self.photoImageView, belowSubview: self.toolBar)
        self.view.addSubview(self.changeCameraBtn)
        self.view.addSubview(self.focusIndicator)
    }
    
    
    // MARK: - 权限
    func checkAuthorization() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        // 第一次进行权限获取
        if videoStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (authorized) in
                if authorized {
                    DispatchQueue.main.async {
                        self.setupCaptureSetting()
                    }
                }
                
            }
        }
        if audioStatus == .notDetermined {
            AVAudioSession.sharedInstance().requestRecordPermission { (authorized) in
                if authorized {
                    DispatchQueue.main.async {
                        self.setupCaptureSetting()
                    }
                }
                
            }
        }

    }
    
    func canAccessAudioDevice() -> Bool {
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        return audioStatus == .authorized
    }
    
    func canAccessVideoDevice() -> Bool {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        return videoStatus == .authorized
    }
    
    func canCapture() -> Bool {
        return self.canAccessAudioDevice() && self.canAccessVideoDevice()
    }
    
    func showAccessHintView() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        let isRequested =  !(videoStatus == .notDetermined || audioStatus == .notDetermined);
        // 是否获取过权限，如果没有，则不会显示提示视图
        if !isRequested{
            return
        }
        /// 显示提示视图
        let isShowHint = !self.canAccessAudioDevice() || !self.canAccessVideoDevice()
        if isShowHint {
            let hint = "请在iPhone的\"设置-隐私\"选项中，允许汇聊访问你的摄像头和麦克风"
            let alertController = UIAlertController(title: hint, message: nil, preferredStyle: .alert)
            let sureAction = UIAlertAction(title: "确定", style: .default) { (action) in
                self.dismissCaptureViewController()
            }
            alertController.addAction(sureAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - 辅助方法
    // MARK: -
    /// 更新录制的进度
    ///
    /// - Parameters:
    ///   - timeInterval: 更新的时间间隔
    ///   - repeatCont: 重复次数
    ///   - handler: 回调闭包
    func startUpdateRecordProgress(timeInterval: Double, repeatCont: Int, handler: @escaping(DispatchSourceTimer? , Int) -> ()) {
        if repeatCont <= 0 {
            return
        }
        
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        var count = repeatCont * 60
        timer.schedule(wallDeadline: .now(), repeating: timeInterval)
        timer.setEventHandler {
            count -= 1
            DispatchQueue.main.async {
                handler(timer, count)
            }
            if (count == 0) {
                timer.cancel()
                self.stopRecordVideo()
            }
        }
        timer.resume()
        self.timer = timer
    }
    
    /// 创建UUID
    ///
    /// - Returns: UUID
    func createFileUUID() -> String {
        return NSUUID().uuidString.uppercased()
    }

    /// 创建压缩后视屏的保存路径
    ///
    /// - Returns: 视屏保存路径
    func createCopressedFileURL() -> URL? {
        let compressedFileName = self.createFileUUID().appending(".mp4")
        if let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first {
            let compressedFilePath =  String(format: "%@/%@", document, compressedFileName)
            return URL(fileURLWithPath: compressedFilePath)
        }
        return nil
    }
    
    /// 当前的录制方向
    func currentVideoCaptureOrientation() -> AVCaptureVideoOrientation {
        var result: AVCaptureVideoOrientation = .portrait
        let deviceOrientation = self.deviceOrientation
        switch deviceOrientation {
        case .portrait, .faceUp, .faceDown:
            result = .portrait
        case .portraitUpsideDown:
            result = .portrait
        case .landscapeLeft:
            result = .landscapeRight
        case .landscapeRight:
            result  = .landscapeLeft
        default:
            result = .portrait
        }
        return result
    }
    
    /// 监听陀螺仪的采集到的数据
    func startAccelerometerUpdates() {
        if !self.motionManager.isDeviceMotionAvailable {
            return;
        }
        if let queue = OperationQueue.current {
            self.motionManager.startAccelerometerUpdates(to: queue) { [weak self] (accelerometerData, error) in
                let x = accelerometerData?.acceleration.x ?? 0
                let y = -(accelerometerData?.acceleration.y ?? 0)
                let z = accelerometerData?.acceleration.z ?? 0
                var deviceAngle = Double.pi / 2.0 - atan2(y, x)
                if deviceAngle > Double.pi {
                    deviceAngle -= 2 * Double.pi
                }
                if z < -0.6 || z > 0.6 {
                    self?.deviceOrientation = .unknown
                }  else {
                    if deviceAngle > -(Double.pi * 0.25) && deviceAngle < (Double.pi * 0.25) {
                        self?.deviceOrientation = .portrait
                    } else if deviceAngle < -(Double.pi * 0.25) && deviceAngle > -(Double.pi * 0.75) {
                        self?.deviceOrientation = .landscapeLeft
                    } else if deviceAngle > Double.pi * 0.25 && deviceAngle < Double.pi * 0.75 {
                        self?.deviceOrientation = .landscapeRight
                    } else  {
                        self?.deviceOrientation = .portraitUpsideDown
                    }
                }
            }
           
            
        }
        
    }
    
    func stopAccelerometerUpdates() {
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    func setAutoFocus() {
        self.changeCuptureConfigurationSafty { (captureDevice) in
            // 聚焦模式
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            } else if captureDevice.isFocusModeSupported(.autoFocus) {
                captureDevice.focusMode = .autoFocus
            }
            /// 曝光模式
            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            } else if captureDevice.isExposureModeSupported(.autoExpose) {
                captureDevice.exposureMode = .autoExpose
            }
        }
        let center = CGPoint(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
        self.focusIndicator.move(to: center)
    }
    
    /// 保存视频到相册
    func saveVideoToLibrary(videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { (saved, error) in
            if nil != error {
                print(error.debugDescription)
            } else {
                print("saved=", saved)
            }
        }
    }
    
    /// 保存视频到
    func saveImageToLibrary() {
        if let image = self.photoImageView.image {
            PHPhotoLibrary.shared().performChanges({
                
                PHAssetChangeRequest.creationRequestForAsset(from: image)
                
                
            }) { (saved, error) in
                print("saved=", saved)
            }
        }
    }
    // MARK: -
    /// 添加手势
    func addGestureRecognizers() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: Selector.handleSingleTapSEL)
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delaysTouchesBegan = true
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector.handleDoubleTapSEL)
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delaysTouchesBegan = true
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: Selector.handlePinchSEL)
        pinchGesture.delegate = self
        
        singleTapGesture.require(toFail: doubleTapGesture)
        
        self.view.addGestureRecognizer(singleTapGesture)
        self.view.addGestureRecognizer(doubleTapGesture)
        self.view.addGestureRecognizer(pinchGesture)
    }
    
    
    /// 操作提示视图
    func showOperationHint() {
        let hintLabel = UILabel()
        hintLabel.text = "轻触拍照，长按消失"
        hintLabel.font = UIFont.systemFont(ofSize: 13)
        hintLabel.textColor = .white
        hintLabel.backgroundColor = UIColor(white: 0, alpha: 0.06)
        hintLabel.layer.cornerRadius = 2
        hintLabel.layer.masksToBounds = true
        hintLabel.textAlignment = .center
        hintLabel.alpha = 0
        
        hintLabel.frame = CGRect(x: (self.view.frame.width - 130) * 0.5, y: self.toolBar.frame.minY - 24, width: 130, height: 24)
        self.view.addSubview(hintLabel)
        UIView.animate(withDuration: 0.25, animations: {
            hintLabel.alpha = 1
            hintLabel.backgroundColor = UIColor(white: 0, alpha: 0.06)
        }, completion: nil);
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(withDuration: 0.5, animations: { [weak hintLabel] in
                hintLabel?.alpha = 0;
                }, completion: { [weak hintLabel] (finished) in
                    hintLabel?.removeFromSuperview()
            })
        }
    }
    
}

// MARK: -  AVAVCaptureSession配置
extension CaptureViewController {
    
    /// 视频/照片/音频设备捕获参数设置
    func configCaptureSession() {
        self.captureSession.beginConfiguration()
        self.configVideo()
        self.configAudio()
        self.configPhoto()
        self.setupVideoPreviewLayer()
        self.captureSession.commitConfiguration()
        self.captureSession.startRunning()
        
    }
    
    func changeCuptureConfigurationSafty(handler: @escaping(AVCaptureDevice)-> ()) {
        let captureDevice = self.videoInput.device
        try! captureDevice.lockForConfiguration()
        self.captureSession.beginConfiguration()
        handler(captureDevice)
        captureDevice.unlockForConfiguration()
        self.captureSession.commitConfiguration()
    }
    
    /// 配置拍照输出参数
    func configPhoto() {
        let photoOutput = AVCaptureStillImageOutput()
        photoOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if self.captureSession.canAddOutput(photoOutput) {
            self.captureSession.addOutput(photoOutput)
        }
        self.photoOutput = photoOutput
    }
    
    /// 配置视屏输入/输出相关参数
    func configVideo()  {
        // 获取摄像头
        if let captureDevice = self.createCaptureDevice(for: AVMediaType.video, position: AVCaptureDevice.Position.back) {
            self.imageCaptureDevice = captureDevice
            self.configVideoInput()
            self.configMovieOutput()
        }
       
    }
    /// 配置视屏输入
    func configVideoInput()  {
        let videoInput = try? AVCaptureDeviceInput(device: self.imageCaptureDevice!)
        if let input = videoInput, self.captureSession.canAddInput(input) {
            self.captureSession.addInput(input)
            self.videoInput = input
        }
    }
    
    /// 配置视屏输出
    func configMovieOutput() {
        let movieOutput = AVCaptureMovieFileOutput()
        if self.captureSession.canAddOutput(movieOutput) {
            self.captureSession.addOutput(movieOutput)
            if let captureConnection = movieOutput.connection(with: .video) {
                if captureConnection.isVideoStabilizationSupported {
                    captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                }
                if captureConnection.isVideoOrientationSupported {
                    captureConnection.videoOrientation = .portrait
                }
                captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor
            }
            self.movieOutput = movieOutput
        }
    }
    
    /// 配置音频输入
    func configAudio() {
        let canAccess = self.canAccessAudioDevice()
        if !canAccess {
            return
        }
        self.audioDevice = AVCaptureDevice.default(for: .audio)
        let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        if let input = audioInput, self.captureSession.canAddInput(input){
            self.captureSession.addInput(input)
            self.audioInput = input
        }
    }
    
    /// 创建视屏捕获设备
    func createCaptureDevice(for mediaType: AVMediaType, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: mediaType);
        var device = devices.first
        for item in devices {
            if (item.position == position) {
                device = item
                break
            }
        }
        return device
    }
    
    // 相机内容实时预览图层
    func setupVideoPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.frame = self.view.bounds
        if let outputConnection = self.movieOutput.connection(with: .video) {
            previewLayer.connection?.videoOrientation = outputConnection.videoOrientation
        }
        previewLayer.videoGravity = .resizeAspectFill
        self.previewContainerView.layer.masksToBounds = true
        self.previewContainerView.layer.addSublayer(previewLayer)
        
        self.captureVideoPreviewLayer =  previewLayer
    }
}

// MARK: - BLCaptureToolBar回调事件处理
extension CaptureViewController {
    func handleToolBarAction(type: BLCaptureToolBarActionType) {
        switch type {
        case .dismiss:
            self.dismissCaptureViewController()
        case .takePhoto:
            self.takePhoto()
        case .startRecordVideo:
            self.startRecordVideo()
        case .stopRecordVideo:
            self.stopRecordVideo()
        case .giveUp:
            self.giveUpCaptureResult()
        case .use:
            self.useCaptureReusult()
        }
    }
    
    /// 隐藏当前控制器
    func dismissCaptureViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// 拍照
    func takePhoto() {
        var connection: AVCaptureConnection?
        for item in self.photoOutput.connections {
            for port in item.inputPorts {
                if (port.mediaType == .video) {
                    connection = item
                    break
                }
            }
        }
        guard (connection != nil) else {
            return
        }
        connection!.videoScaleAndCropFactor  = effectiveScale
        self.photoOutput.captureStillImageAsynchronously(from: connection!) { [weak self] (buffer, error) in
            if nil != error {
               print(error.debugDescription)
            } else {
                if let strongSelf = self,  nil != buffer {
                    let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!)
                    let originImage = UIImage(data: data!)
                    let size = CGSize(width: strongSelf.captureVideoPreviewLayer.bounds.size.width * 2.0, height: strongSelf.captureVideoPreviewLayer.bounds.size.height * 2.0)
                    let scaleImage = originImage?.resizedImage(with: .scaleAspectFill, bounds: size, interpolationQuality: .high)
                    var cropFrame: CGRect = .zero
                    if let existImage = scaleImage {
                        let x = (existImage.size.width - size.width) * 0.5
                        let y = (existImage.size.height - size.height) * 0.5
                        cropFrame = CGRect(x: x, y: y, width: size.width, height: size.height)
                    }
                    var croppedImage = originImage
                    if strongSelf.videoInput.device.position == .front {
                        croppedImage = scaleImage?.croppedImage(cropFrame, with: .upMirrored)
                    } else {
                        croppedImage = scaleImage?.croppedImage(cropFrame)
                    }
                    croppedImage = croppedImage?.change(with: strongSelf.deviceOrientation)
                    strongSelf.photoImageView.image = croppedImage
                    strongSelf.photoImageView.isHidden = false
                    strongSelf.outputFileType = .image
                    strongSelf.toolBar.finishCaptureProgress()
                    strongSelf.changeCameraBtn.isHidden = true
                    if let image = croppedImage {
                        strongSelf.photoData = image.jpegData(compressionQuality: 1.0)
                    }
                }
            }
        }
        
    }
    
    /// 开始录制视频
    func startRecordVideo() {
        if let captureConnection = self.movieOutput.connection(with: .video), captureConnection.isVideoOrientationSupported {
            captureConnection.videoOrientation = self.currentVideoCaptureOrientation()
            let videoName = self.createFileUUID()
            let outputFilePath = String(format: "%@%@%@", NSTemporaryDirectory(), videoName, ".mov")
            let outputFileURL = URL(fileURLWithPath: outputFilePath)
            self.movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
            self.videoURL = outputFileURL
        }
    }
    
    /// 结束录制视频
    func stopRecordVideo() {
        self.movieOutput.stopRecording()
        self.timer?.cancel()
        outputFileType = .video
        self.toolBar.captureActionEnd()
        self.changeCameraBtn.isHidden = true
    }
    
    /// 放弃捕获的视频或照片
    func giveUpCaptureResult() {
        self.removePlayer()
        self.photoImageView.isHidden = true
        self.photoImageView.image = nil
        if let url = self.videoURL {
             try? FileManager.default.removeItem(at: url)
        }
        self.outputFileType = .image
        self.changeCameraBtn.isHidden = false
    }
    
    /// 使用捕获的视频
    func useCaptureReusult() {
        self.toolBar.isUserInteractionEnabled = false;
        switch self.outputFileType {
        case .image:
            self.delegate?.captureViewController(vc: self, didFinishTakePhoto: self.photoData, error: nil)
            self.saveImageToLibrary()
        case .video:
            if let url = self.videoURL {
                self.delegate?.captureViewController(vc: self, didFinishRecordVideo: url, error: nil)
                self.saveVideoToLibrary(videoURL: url)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
             self.dismissCaptureViewController()
        }
    }
}

// MARK: - 播放器相关
extension CaptureViewController {
    
    /// 初始化播放器
    func setupPlayer() {
        if let url = self.videoURL {
            playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            self.addPlayerObservers()
            self.playerView.frame = self.view.bounds;
            self.playerView.player = player;
            self.view.insertSubview(self.playerView, belowSubview: self.toolBar)
           
            player?.play()
        }
    }
    
    /// 移除播放器
    func removePlayer() {
        if self.playerView.superview != nil {
            self.view.sendSubviewToBack(self.playerView)
            self.playerView.removeFromSuperview()
            self.player?.replaceCurrentItem(with: nil)
            self.player = nil
            self.playerItem = nil
        }
    }
    
    /// 添加观察者
    func addPlayerObservers() {
        if (self.player?.currentItem) != nil {
            NotificationCenter.default.addObserver(self, selector:#selector(CaptureViewController.handlePlayEnd) , name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    /// 循环播放
    @objc func handlePlayEnd(notification: Notification) {
        if let player = self.player {
            player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
            player.play()
        }
    }
}


// MARK: - 视频/图片处理
extension CaptureViewController {
    
    /// 视频压缩
    func compressVideo() {
        guard let url = self.videoURL else {
            return
        }
        let avAsset = AVURLAsset(url: url)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        if compatiblePresets.contains(AVAssetExportPreset640x480) {
            let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPreset640x480)
            let compressedVideoURL = self.createCopressedFileURL()
            exportSession?.outputURL = compressedVideoURL
            exportSession?.shouldOptimizeForNetworkUse = true
            exportSession?.outputFileType = AVFileType.mp4
            exportSession?.exportAsynchronously(completionHandler: {
                if exportSession?.status == .completed {
                    guard let targetURL = compressedVideoURL else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: {
                              self.delegate?.captureViewController(vc: self, didFinishRecordVideo: targetURL, error: nil)
                        })
                    }
                    self.saveVideoToLibrary(videoURL: targetURL)
                }
            })
        }
    }
    
    
    
}

// MARK: - 点击事件/手势处理
extension CaptureViewController {
    
    /// 切换摄像头
    @objc func handleChangeCamera(sender: UIButton) {
       self.changeCamera()
    }
    
    /// 单机改变焦点
    ///
    /// - Parameter sender: 手势
    @objc func handleSigleTap(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: self.view)
        self.changeFocus(point: touchPoint)
    }
    
    /// 改变焦点
    ///
    /// - Parameter point: 焦点位置
    func changeFocus(point: CGPoint) {
        let cameraPoint = self.captureVideoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
        self.changeCuptureConfigurationSafty { (captureDevice) in
            // 聚焦模式
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            } else if captureDevice.isFocusModeSupported(.autoFocus) {
                captureDevice.focusMode = .autoFocus
            }

            // 焦点位置
            if captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = cameraPoint
                self.focusIndicator.move(to: point)
            }
            
            /// 曝光模式
            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            } else if captureDevice.isExposureModeSupported(.autoExpose) {
                captureDevice.exposureMode = .autoExpose
            }

            // 曝光点位置
            if captureDevice.isExposurePointOfInterestSupported {
                captureDevice.exposurePointOfInterest = cameraPoint
            }

        }
    }
    
    /// 双击切换摄像头
    @objc func handleDoubleTap(sender: UIGestureRecognizer) {
        self.changeCamera()
    }
    
    /// 切换焦距
    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        
        self.changeCuptureConfigurationSafty { (captureDevice) in
            var canChange = true
            for i in 0 ..< sender.numberOfTouches {
                let location = sender.location(ofTouch: i, in: sender.view)
                let covertedLocation = self.captureVideoPreviewLayer.convert(location, from: self.previewContainerView.layer)
                if !self.captureVideoPreviewLayer.contains(covertedLocation) {
                    canChange = false
                    break
                }
            }
            
            if canChange {
                self.effectiveScale = self.lastScale * sender.scale;
                self.effectiveScale = max(self.effectiveScale, 1.0)
        
                let validScale = self.imageCaptureDevice?.activeFormat.videoMaxZoomFactor ?? 1.0
                if self.effectiveScale > validScale {
                    self.effectiveScale = validScale
                }
                
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.025)
                let transForm = CGAffineTransform(scaleX: self.effectiveScale, y: self.effectiveScale)
                self.captureVideoPreviewLayer.setAffineTransform(transForm)
                CATransaction.commit()
            }
        }
    }

    
    /// 切换摄像头
    func changeCamera() {
        guard let captureDevice = self.imageCaptureDevice else {
            return
        }
        switch captureDevice.position {
        case .front:
            self.imageCaptureDevice = self.createCaptureDevice(for: .video, position: .back)
        case .back:
            self.imageCaptureDevice = self.createCaptureDevice(for: .video, position: .front)
        default:
            print("未知位置的摄像头")
            return
        }
        if nil == self.imageCaptureDevice {
            return
        }
        self.changeCuptureConfigurationSafty { (captureDevice) in
            let newVideoInput = try? AVCaptureDeviceInput(device: self.imageCaptureDevice!)
            if let input = newVideoInput {
                self.captureSession.removeInput(self.videoInput)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.videoInput = newVideoInput
                    self.videoMirored()
                } else {
                    self.captureSession.addInput(self.videoInput)
                }
            } else {
                print("切换摄像头失败")
            }
        }
    }
    
    /// 处理自拍镜像问题
    func videoMirored() {
        guard let captureDevice = self.imageCaptureDevice else {
            return
        }
        
        guard let connection = self.movieOutput.connection(with: .video) else {
            return
        }
        switch captureDevice.position {
        case .front:
            connection.isVideoMirrored = true
        case .back:
            connection.isVideoMirrored = false
        default:
            connection.isVideoMirrored = true
            return
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CaptureViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.toolBar.startRecordProgress()
        self.startUpdateRecordProgress(timeInterval: 1.0/60, repeatCont: self.maxRecordTime) { [weak self] (timer, remainRecordTime) in
            if let strongSelf = self {
                let recordTime = strongSelf.maxRecordTime * 60  - remainRecordTime
                let progress = Double(recordTime) / Double(strongSelf.maxRecordTime * 60)
                print(progress)
                strongSelf.toolBar.updateProgress(progress: progress)
            }
        }
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.toolBar.finishCaptureProgress()
        self.setupPlayer()
    }
    
}

extension CaptureViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPinchGestureRecognizer) {
            lastScale = effectiveScale
        }
        return true
    }

}
