//
//  NIMDownloadManager.h
//  NIMDownloadManager
//
//  Created by BaiLun on 2018/11/2.
//  Copyright © 2018 bailun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^NIMDownloadManagerCompletionHandler)(void);

@interface NIMDownloadManager : NSObject

@property (nonatomic, strong)NIMDownloadManagerCompletionHandler completionHandler;

+ (instancetype)shareManager;

/**
 视频下载
 
 @param remotePath 视频远程路径
 @param localPath 视频本地保存路径
 */
- (void)downoadVideoFrom:(NSString *)remotePath to: (NSString *)localPath;


@end

