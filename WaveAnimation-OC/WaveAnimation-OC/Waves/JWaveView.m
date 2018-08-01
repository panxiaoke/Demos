//
//  JWaveView.m
//  WaveAnimation-OC
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "JWaveView.h"

@interface JWaveView ()

@property (nonatomic, strong) CADisplayLink    *displayLink;  // UI刷新器

@property (nonatomic, strong) CAShapeLayer     *waveLayer;    // 波浪绘制图层


@end

@implementation JWaveView {
    
    CGFloat _waveA;         // 振福
    CGFloat _waveW;         // 周期
    CGFloat _offsetX;       // 偏移量
    CGFloat _currentK;      // 当前的高度
    CGFloat _waveSpeed;     // 波浪的速度
    CGFloat _waveWidth;     // 波浪宽度
    JWaveViewType _type;    // 波浪类型
}

#pragma mark - Life Circle

- (instancetype)initWithFrame:(CGRect)frame type:(JWaveViewType)type {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.layer.masksToBounds = YES;
        
        _type = type;
        
        [self setupData];
        [self setupUI];
        [self setupDisplayLink];
    }
    
    return self;
    
}

+ (instancetype)waveViewWithFrame:(CGRect)frame type:(JWaveViewType)type {
    
    return [[self alloc] initWithFrame:frame type:type];
}

#pragma mark - Setup Data

- (void)setupData {
    
    _waveA = 12;
    _waveW = 0.5 / 30;
    _currentK = self.frame.size.height * 0.5;
    _waveSpeed = 0.03;
    _waveWidth = self.frame.size.width;
    _waveColor = [UIColor colorWithRed:86/255.0 green:202/255.0 blue:139/255.0 alpha:1];
    
}

#pragma mark - Setup UI

- (void)setupUI {
    
    [self.layer addSublayer:self.waveLayer];
}

#pragma mark - Private Method

- (void)setupDisplayLink {
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWave)];
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
}

- (void)updateWave {
    
    _offsetX += _waveSpeed; // 计算当前偏移量
     CGFloat y = _currentK;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 0, y);
    for (NSInteger i = 0; i < _waveWidth; i++) {
        if (JWaveViewTypeSin == _type) {
            y = _waveA * sin(_waveW * i + _offsetX) + _currentK;
        } else {
            y = _waveA * cos(_waveW * i + _offsetX) + _currentK;
          
        }
        CGPathAddLineToPoint(path, nil, i, y);
       
    }
    CGPathAddLineToPoint(path, nil, _waveWidth, 0);
    CGPathAddLineToPoint(path, nil, 0, 0);
    CGPathCloseSubpath(path);
    
    self.waveLayer.path = path;
    
    CGPathRelease(path);
}


#pragma mark - Getter

- (CAShapeLayer *)waveLayer {
    
    if (nil == _waveLayer) {
        
        CAShapeLayer  *shapLayer = [CAShapeLayer layer];
        shapLayer.fillColor = self.waveColor.CGColor;
        _waveLayer = shapLayer;
    }
    
    return _waveLayer;
}

#pragma mark - Setter

- (void)setWaveColor:(UIColor *)waveColor {
    
    _waveColor = waveColor;
    self.waveLayer.fillColor = waveColor.CGColor;
}




@end
