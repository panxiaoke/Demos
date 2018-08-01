//
//  CornerView.m
//  BezierPath
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "CornerView.h"

@implementation CornerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)];
    [[UIColor orangeColor] setStroke];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    [path stroke];
    self.layer.mask = layer;
}


@end
