//
//  NIMDownloadManager.m
//  NIMDownloadManager
//
//  Created by BaiLun on 2018/11/2.
//  Copyright © 2018 bailun. All rights reserved.
//

#import "NIMDownloadManager.h"
#import "NIMDownloadModel.h"

@interface NIMDownloadManager ()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSMutableDictionary *downloads;

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
        _downloads = [NSMutableDictionary dictionary];
//        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.bailun.fxchat.video.dowload"];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.discretionary = YES;
        config.sessionSendsLaunchEvents = true;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - Private
- (NSString *)savedDirectoryFromLocalPath:(NSString *)localPath {
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSArray *components = [localPath componentsSeparatedByString:@"/"];
    NSInteger documentIndex = -1;
    for (NSInteger i = 0; i < components.count; i++) {
        if ([components[i] isEqualToString:document]) {
            documentIndex = i;
            break;
        }
    }
    NSString *directory = nil;
    if (documentIndex >= 0 && documentIndex < components.count - 1) {
        NSRange subDirectoriesRange = NSMakeRange(documentIndex + 1, components.count - 1);
        NSArray *savedPathComponets = [components subarrayWithRange:subDirectoriesRange];
        directory = [savedPathComponets componentsJoinedByString:@"/"];
    } else {
        directory = [document stringByAppendingPathComponent:@"FXChat/Session/Video"];
    }
    return directory;
}

#pragma mark - Public
- (void)downoadVideoFrom:(NSString *)remotePath to:(NSString *)localPath {
    if (remotePath && localPath) {
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath: localPath] || [self.downloads valueForKey:remotePath];
        if (isExist) {
            return;
        }
        
        NIMDownloadModel *dowload = [[NIMDownloadModel alloc] init];
        dowload.remotePath = remotePath;
        dowload.directory = [self savedDirectoryFromLocalPath: localPath];
        NSArray *componts = [localPath componentsSeparatedByString:@"/"];
        dowload.name = componts.lastObject;
        [self.downloads setValue:dowload forKey:remotePath];
        
        NSURL *reomteURL = [NSURL URLWithString:remotePath];
        NSURLSessionTask *downloadTask = [self.session downloadTaskWithURL:reomteURL];
        [downloadTask resume];
    }
    
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSURL *originURL = downloadTask.originalRequest.URL;
    NSString *remotePath = [NSString stringWithFormat:@"%@", originURL];
    if (remotePath) {
        NIMDownloadModel *dowload = [self.downloads valueForKey:remotePath];
        if (dowload.name && dowload.directory) {
            BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:dowload.directory];
            if (!exist) {
                NSError *error = nil;
                [[NSFileManager defaultManager] createDirectoryAtPath:dowload.directory withIntermediateDirectories:YES attributes:nil error:&error];
                if (error) {

                }
            }
          
            NSString *savedPath = [dowload.directory stringByAppendingPathComponent:dowload.name];
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:savedPath] error:&error];
        }
    }
}

@end
