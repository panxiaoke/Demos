//
//  ValView.m
//  BezierPath
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "ValView.h"

@implementation ValView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 */



- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(rect.origin.x + 1, rect.origin.y + 1, rect.size.width - 2, rect.size.height - 2)];
    path.lineWidth = 1.0f * [UIScreen mainScreen].scale;
    [[UIColor redColor] setStroke];
    [path stroke];
}

@end
