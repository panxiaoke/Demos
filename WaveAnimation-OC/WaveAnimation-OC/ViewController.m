//
//  ViewController.m
//  WaveAnimation-OC
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "ViewController.h"

#import "JWaveView.h"

@interface ViewController ()

@property (nonatomic, strong) JWaveView    *sinWaveView; // Sin波浪

@property (nonatomic, strong) JWaveView    *cosWaveView; // Cos波浪

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.sinWaveView];
    
    [self.view addSubview:self.cosWaveView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getter

- (JWaveView *)sinWaveView {
    
    if (nil == _sinWaveView) {
        
        JWaveView  *waveView = [[JWaveView alloc] initWithFrame:CGRectMake(0, -20, [UIScreen mainScreen].bounds.size.width, 220) type:JWaveViewTypeSin];
        waveView.alpha = 0.6;
        _sinWaveView = waveView;
    }
    
    return _sinWaveView;
}

- (JWaveView *)cosWaveView {
    
    if (nil == _cosWaveView) {
        
        JWaveView  *waveView = [[JWaveView alloc] initWithFrame:CGRectMake(0, -20, [UIScreen mainScreen].bounds.size.width, 220) type:JWaveViewTypeCos];
        waveView.alpha = 0.6;
        _cosWaveView = waveView;
    }
    
    return _cosWaveView;
}


@end
