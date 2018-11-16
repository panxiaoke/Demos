//
//  ViewController.m
//  数组枚举
//
//  Created by BaiLun on 2018/11/14.
//  Copyright © 2018 bailun. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _items = [NSMutableArray array];
    [self insertObject:100000];
   
}

- (void)insertObject:(NSInteger)count {
    for (NSInteger i = 0; i < count; i++) {
        [_items addObject:@(i)];
    }
}

- (void)enumItems {
    NSArray *array = self.items;
    for (NSNumber *num in array) {
        NSLog(@"testdata----%ld", num.integerValue);
    }
}

- (IBAction)handleArrayEnum:(id)sender {
    
    [self enumItems];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self insertObject:1000];
//    });
}

@end
