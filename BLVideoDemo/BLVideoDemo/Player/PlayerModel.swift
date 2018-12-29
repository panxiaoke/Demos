//
//  PlayerModel.swift
//  BLVideoDemo
//
//  Created by BaiLun on 2018/10/19.
//  Copyright © 2018 qinrongjun. All rights reserved.
//

import Foundation
import UIKit


@objcMembers class PlayerModel: NSObject {
    var videoURL: URL!      // 视频地址
    var duration: Int = 0   // 视频时长，单位：秒
    var autoPlay = true     // 是否自动播放
    var coverImageURL: URL? // 视频封面图
    var coverPlaceolderImage: UIImage? = UIImage(named: "cover_image")  //视频封面的占位图
    var isMuted = false     // 是否静音播放
    var isLocal = false     // 是否是本地视频
    var sourcePath: String? // 服务器路径
    var targetPath: String? // 本地保存路径
}
