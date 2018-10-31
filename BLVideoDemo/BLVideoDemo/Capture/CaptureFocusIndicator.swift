//
//  BLFocusIndicator.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/15.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit

class CaptureFocusIndicator: UIView {

    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setLineWidth(1)
        UIColor.green.set()
        
        let lineLength: CGFloat = 6
        // 矩形
        let path = UIBezierPath(rect: self.bounds)
        // 小短线
        // 上
        path.move(to: CGPoint(x: self.frame.width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width * 0.5, y: lineLength))
        // 右
        path.move(to: CGPoint(x: self.frame.width - lineLength, y: self.frame.height * 0.5))
        path.addLine(to: CGPoint(x: self.frame.width , y: self.frame.height * 0.5))
        // 下
        path.move(to: CGPoint(x: self.frame.width * 0.5, y: self.frame.height))
        path.addLine(to: CGPoint(x: self.frame.width * 0.5, y: self.frame.height - lineLength))
        // 右
        path.move(to: CGPoint(x: 0, y: self.frame.height * 0.5))
        path.addLine(to: CGPoint(x: lineLength, y: self.frame.height * 0.5))
        
        ctx?.addPath(path.cgPath)
        ctx?.strokePath()
    }
    
    /// 移动自己的位置
    ///
    /// - Parameter point: center
    func move(to point: CGPoint) {
        if !self.isHidden {
            return
        }
        self.isHidden = false
        self.center = point
        let aniamtion = CABasicAnimation(keyPath: "transform.scale")
        aniamtion.fromValue = 1.3
        aniamtion.toValue = 1
        aniamtion.duration = 0.25
        self.layer.add(aniamtion, forKey: "show")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.isHidden = true
        }
    }

}
