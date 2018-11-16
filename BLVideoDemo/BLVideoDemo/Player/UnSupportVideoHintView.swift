//
//  UnSupportVideoHintView.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/11/7.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import UIKit
import SnapKit

class UnSupportVideoHintView: UIView {
    
    lazy var hintImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = R.image.chat_player_unsupport()
        return imageView
    }()
    
    lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = UIColor(red: 96/255.0, green: 96/255.0, blue: 96/255.0, alpha: 1)
        label.text = "无法加载视频"
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

// MARK: - UI
extension UnSupportVideoHintView {
    func setupUI() {
        self.backgroundColor = UIColor(red: 221/255.0, green: 221/255.0, blue: 221/255.0, alpha: 1)
        
        self.setupSubviews()
    }
    
    func setupSubviews() {
        self.addSubview(hintImageView)
        hintImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.bottom.equalToSuperview().offset(-106)
        }
        
        self.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { (make) in
            make.top.equalTo(hintImageView.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
        }
    }
}

