//
//  TestVC.m
//  YBNotificationDemo
//
//  Created by 杨少 on 2018/2/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "TestVC.h"

@interface TestVC ()

@property (nonatomic, strong) id any;

@end

@implementation TestVC
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
    if (_any) {
        [YBNotificationCenter.defaultCenter removeObserver:_any];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];

//    [YBNotificationCenter.defaultCenter addObserver:self selector:@selector(respondsToNotice:) name:@"test1" object:nil];
//    [YBNotificationCenter.defaultCenter addObserver:self selector:@selector(respondsToNotice:) name:@"test2" object:nil];
    __weak typeof(self) wSelf = self;
    _any = [YBNotificationCenter.defaultCenter addObserverForName:@"test1" object:nil queue:nil usingBlock:^(YBNotification * _Nonnull noti) {
        id obj = noti.object;
        NSDictionary *dic = noti.userInfo;
        NSLog(@"\n- self:%@ \n- obj:%@ \n- notificationInfo:%@", wSelf, obj, dic);
    }];
    
}

- (void)respondsToNotice:(YBNotification *)noti {
    id obj = noti.object;
    NSDictionary *dic = noti.userInfo;
    NSLog(@"\n- self:%@ \n- obj:%@ \n- notificationInfo:%@", self, obj, dic);
}

- (IBAction)clickSend:(id)sender {
    
    [YBNotificationCenter.defaultCenter postNotificationName:@"test1" object:nil userInfo:@{@"key":@"value"}];
    [YBNotificationCenter.defaultCenter postNotificationName:@"test2" object:nil userInfo:@{@"key":@"value"}];
}

- (IBAction)clickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
