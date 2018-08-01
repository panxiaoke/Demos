//
//  RectView.m
//  BezierPath
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "RectView.h"

@implementation RectView

/*
 Only override drawRect: if you perform custom drawing.
 An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect {
//     Drawing code
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(rect.origin.x + 2, rect.origin.y + 2, rect.size.width -4, rect.size.height - 4)];
    path.lineWidth = 2.0f * [UIScreen mainScreen].scale;
    [[UIColor redColor] setStroke];
    [[UIColor yellowColor] setFill];
    [path stroke];
    [path fill];
    
}


@end
