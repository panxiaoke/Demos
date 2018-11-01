//
//  CaptureProgressView.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/13.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit

class CircleProgressView: UIView {
    
    var progress: Double = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 0.2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setLineWidth(8)
        ctx?.setLineCap(.butt)
        UIColor(red: 46/255.0, green: 169/255.0, blue: 223/255.0, alpha: 1).set()
        let center = CGPoint(x: self.frame.width * 0.5, y: self.frame.height * 0.5)
        let startAngle = CGFloat(Double.pi * 1.5)
        let endAngle = startAngle + CGFloat(Double.pi * 2 * progress)
        let radius = self.frame.width * 0.5
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        ctx?.addPath(path.cgPath)
        ctx?.strokePath()
        
    }
}

class CaptureProgressView: UIVisualEffectView {
    
    var progress: Double = 0 {
        didSet {
            self.circleProgressView.progress = progress
        }
    }
    
    lazy var circleProgressView: CircleProgressView = {
        let view = CircleProgressView()
        return view
    }()

    init() {
        super.init(effect: UIBlurEffect(style: .light))
        self.contentView.addSubview(self.circleProgressView)
       
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.width * 0.5
        self.layer.masksToBounds = true
        self.contentView.addSubview(self.circleProgressView)
        self.circleProgressView.frame = self.contentView.bounds;
    }
    
}

// MARK: - Public 
extension  CaptureProgressView {
    func start(){
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 120.0 / 75
        animation.duration = 0.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        self.layer.add(animation, forKey: "biggerAni")
    }
    
    func reset() {
        self.progress = 0
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1
        animation.duration = 0
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        self.layer.add(animation, forKey: "resetAni")
    }
}
