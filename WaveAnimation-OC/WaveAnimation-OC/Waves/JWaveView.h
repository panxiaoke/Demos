//
//  JWaveView.h
//  WaveAnimation-OC
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JWaveViewType) {
    JWaveViewTypeSin,
    JWaveViewTypeCos
};

@interface JWaveView : UIView

@property (nonatomic, strong) UIColor    *waveColor;

- (instancetype)initWithFrame:(CGRect)frame type:(JWaveViewType)type;

+ (instancetype)waveViewWithFrame:(CGRect)frame type:(JWaveViewType)type;


@end
