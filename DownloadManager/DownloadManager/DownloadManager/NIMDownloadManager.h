//
//  DownloadManager.h
//  DownloadManager
//
//  Created by BaiLun on 2018/11/2.
//  Copyright © 2018 bailun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIMDownloadManager : NSObject

+ (instancetype)shareManager;

/**
 视频下载
 
 @param remotePath 视频远程路径
 @param localPath 视频本地保存路径
 @return 下载器
 */
- (void)downoadVideoFrom:(NSString *)remotePath to: (NSString *)localPath;

@end

NS_ASSUME_NONNULL_END
