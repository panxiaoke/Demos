//
//  ViewController.m
//  BezierPath
//
//  Created by qinrongjun on 2018/8/1.
//  Copyright © 2018年 qinrongjun. All rights reserved.
//

#import "ViewController.h"

#import "RectView.h"
#import "ValView.h"
#import "CornerView.h"
#import "CircleView.h"

@interface ViewController ()

@property (nonatomic, strong) RectView      *rectView;

@property (nonatomic, strong) ValView       *valView;

@property (nonatomic, strong) CornerView    *cornerView;

@property (nonatomic, strong) CircleView    *circleView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.rectView];
    
    [self.view addSubview:self.valView];
    
    [self.view addSubview:self.cornerView];
    
    [self.view addSubview:self.circleView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getter

- (RectView *)rectView {
    
    if (nil == _rectView) {
        
        RectView  *view = [[RectView alloc] initWithFrame:CGRectMake(10, 20, 100, 100)];
        view.backgroundColor = [UIColor whiteColor];
        _rectView = view;
    }
    
    return _rectView;
}

- (ValView *)valView {
    
    if (nil == _valView) {
        
        /**
         * 圆就是特殊的椭圆
         * 即长轴等于短轴
         */
        ValView  *view = [[ValView alloc] initWithFrame:CGRectMake(120, 20, 100, 80)];
        view.backgroundColor = [UIColor blackColor];
        _valView = view;
    }
    
    return _valView;
}

- (CornerView *)cornerView {
    
    if (nil == _cornerView) {
        
        CornerView  *view = [[CornerView alloc] initWithFrame:CGRectMake(230, 20, 80, 100)];
        view.backgroundColor = [UIColor orangeColor];
        view.layer.masksToBounds = YES;
        _cornerView = view;
    }
    
    return _cornerView;
}

- (CircleView *)circleView {
    
    if (nil == _circleView) {
        
        CircleView  *view = [[CircleView alloc] initWithFrame:CGRectMake(10, 130, 100, 100)];
        view.backgroundColor = [UIColor whiteColor];
        _circleView = view;
    }
    
    return _circleView;
}

@end
