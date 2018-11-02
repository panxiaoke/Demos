//
//  DownloadManager.m
//  DownloadManager
//
//  Created by BaiLun on 2018/11/2.
//  Copyright © 2018 bailun. All rights reserved.
//

#import "NIMDownloadManager.h"

@interface NIMDownloadManager ()

@property (nonatomic, strong) NSURLSession *normalSession;

@end

@implementation NIMDownloadManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static NIMDownloadManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (BOOL)videoExistAtPath:(NSString *)videoPath {
    return [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
}

#pragma mark - Public

- (void)downoadVideoFrom:(NSString *)remotePath to:(NSString *)localPath {
    BOOL exist = [self videoExistAtPath: localPath];
    if (exist) {
        return;
    }
    if (remotePath) {
        NSString *fileName = localPath.lastPathComponent;
        NSRange fileNameRange = [localPath rangeOfString:fileName];
        if (fileNameRange.location != NSNotFound && fileNameRange.location > 0) {
            NSString *folder = [localPath substringToIndex:fileNameRange.location - 1];
        }
    }
}

@end
