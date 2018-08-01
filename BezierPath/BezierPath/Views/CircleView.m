//
//  CircleView.m
//  BezierPath
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "CircleView.h"

@implementation CircleView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
//    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(rect.size.width * 0.5, rect.size.width * 0.5) radius: rect.size.width * 0.4 startAngle:0 endAngle:M_PI clockwise:YES];
//    path.lineWidth = 1.0f;
//    [[UIColor redColor] setFill];
//    [[UIColor greenColor] setStroke];
//    [path stroke];
//    [path fill];
    
    NSArray *nums = @[@0.3, @0.2, @0.1, @0.4];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat startAngle = 0, endAngle = 0;
    for (NSNumber *num in nums) {
        CGFloat rate = [num floatValue];
        startAngle = endAngle;
        endAngle = startAngle + M_PI * 2 *rate;
        [path addArcWithCenter: CGPointMake(rect.size.width * 0.5, rect.size.width * 0.5) radius:rect.size.width * 0.4 startAngle:startAngle endAngle:endAngle clockwise: YES];
        [[UIColor clearColor] setStroke];
        CGFloat r = arc4random() % 256 * 1.0 / 255.0;
        CGFloat g = arc4random() % 256 * 1.0 / 255.0;
        CGFloat b = arc4random() % 256 * 1.0 / 255.0;
        [[UIColor colorWithRed:r green:g blue:b alpha:1] setFill];
        [path stroke];
        [path fill];
    }
}


@end
