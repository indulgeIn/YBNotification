//
//  ViewController.m
//  YBNotificationDemo
//
//  Created by 杨少 on 2018/2/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "ViewController.h"
#import "TestVC.h"

@interface ViewController ()

@property (nonatomic, strong) NSObject *obj0;
@property (nonatomic, strong) NSObject *obj1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _obj0 = [NSObject new];
    _obj1 = [NSObject new];
    NSLog(@"_obj0:%@ _obj1:%@", _obj0, _obj1);
    
    [YBNotificationCenter.defaultCenter addObserver:self selector:@selector(respondsToNotice:) name:@"test0" object:nil];
//    [YBNotificationCenter.defaultCenter addObserver:self selector:@selector(respondsToNotice:) name:nil object:nil];

}

- (void)respondsToNotice:(YBNotification *)noti {
    id obj = noti.object;
    NSDictionary *dic = noti.userInfo;
    NSLog(@"\n- self:%@ \n- obj:%@ \n- notificationInfo:%@", self, obj, dic);
}

- (IBAction)clickButton0:(id)sender {
    [YBNotificationCenter.defaultCenter postNotificationName:@"test1" object:_obj0 userInfo:@{@"key":@"value"}];
}
- (IBAction)clickButton1:(id)sender {
    [YBNotificationCenter.defaultCenter removeObserver:self name:@"test0" object:nil];
}
- (IBAction)clickButton2:(id)sender {
    TestVC *vc = [TestVC new];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
