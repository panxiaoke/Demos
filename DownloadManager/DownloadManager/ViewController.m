//
//  ViewController.m
//  DownloadManager
//
//  Created by BaiLun on 2018/11/2.
//  Copyright © 2018 bailun. All rights reserved.
//

#import "ViewController.h"
#import "NIMDownloadManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)dowload:(id)sender {
    
    NSString *remotePath = @"https://nim.nosdn.127.net/NDQwMTA1MQ==/bmltYV8xNzgzNzYzMjU0XzE1NDA5OTM5ODg3ODdfYjkzMzEwOGQtODQ4My00OWJlLWExOTgtMjMyOGExYWUzOTBm";
    NSString *localPath = @"var/mobile/Containers/Data/Application/38083E2C-3568-4E80-836D-863C2888304A/Documents/NIMSDK/5258a0be56e88288df05cbfb293cb78c/Global/Resources/f356f72c58730d0fe0bd5cb86eb54271.mp4";
    [[NIMDownloadManager shareManager] downoadVideoFrom:remotePath to:localPath];
}


@end
