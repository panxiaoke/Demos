//
//  ViewController.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/13.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var url: URL?

    @IBOutlet weak var sliderBar: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        SessionDrafPlistManager.shared.createPlist(name: "test.plist", removeOld: true)
        for item in 0..<10 {
            SessionDrafPlistManager.shared.addValue(to: "test.plist", value: arc4random()/10000, key: String(describing: item))
        }
        sliderBar.setThumbImage(UIImage(named: "dot"), for: .normal)
        sliderBar.setThumbImage(UIImage(named: "dot"), for: .highlighted)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.url = nil
    }

    @IBAction func slider(_ sender: UISlider) {
        print(sender.value)
    }
    
    @IBAction func startRecord(_ sender: UIButton) {
        
        let capatureViewController = CaptureViewController()
        capatureViewController.delegate  = self
        self.present(capatureViewController, animated: true, completion: nil)
    }
    @IBAction func add(_ sender: Any) {
        SessionDrafPlistManager.shared.addValue(to: "test.plist", value: "9999", key: "100")
    }

    @IBAction func deleteItem(_ sender: Any) {
        SessionDrafPlistManager.shared.removeValue(from: "test.plist", key: "100")
    }
    
    @IBAction func query(_ sender: Any) {
        print(SessionDrafPlistManager.shared.queryValue(from: "test.plist", key: "1") ?? "未找到这个值")
    }
    
    @IBAction func update(_ sender: Any) {
        SessionDrafPlistManager.shared.updateValue(to: "test.plist", newValue: "ppdfsjiaf", key: "1")
    }
    
    @IBAction func showAllItems(_ sender: Any) {
      
    }
    
    @IBAction func playVideo(_ sender: Any) {
        if  let urlStr = Bundle.main.path(forResource: "kongfu", ofType: "mp4") {
            url = URL(fileURLWithPath: urlStr)
            self.play()
        }
    }
    
    func play() {
        if let videoURL  = self.url {
            let playerModel = PlayerModel()
            playerModel.videoURL = videoURL
            let player = KFCPlayer(model: playerModel)
            player.show(from: self.view)
        }
    }
}

extension ViewController: CaptureViewControllerDelegate {
    func captureViewController(vc: CaptureViewController, didFinishTakePhoto photoData: Data?, error: Error?) {
        
    }
    
    func captureViewController(vc: CaptureViewController, didFinishRecordVideo videoURL: URL, error: Error?) {
       self.url = videoURL
    }
    
   
}

