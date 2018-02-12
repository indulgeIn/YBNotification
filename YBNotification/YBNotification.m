//
//  YBNotification.m
//  YBNotificationDemo
//
//  Created by 杨少 on 2018/2/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBNotification.h"


@interface YBNotification ()

@property (copy) NSString *name;
@property (weak) id object;
@property (copy) NSDictionary *userInfo;

@end

@implementation YBNotification

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
    if (!name || ![name isKindOfClass:[NSString class]]) {
        return nil;
    }
    YBNotification *noti = [YBNotification new];
    noti.name = name;
    noti.object = object;
    noti.userInfo = userInfo;
    return noti;
}

@end


@interface YBObserverInfoModel : NSObject

@property (weak) id observer;
@property (assign) SEL selector;
@property (weak) id object;
@property (copy) NSString *name;

@end

@implementation YBObserverInfoModel

@end


static NSString *key_observersDic_noContent = @"key_observersDic_noContent";

@interface YBNotificationCenter ()

@property (class, strong) YBNotificationCenter *defaultCenter;
@property (strong) NSMutableDictionary *observersDic;

@end

@implementation YBNotificationCenter

#pragma mark 添加通知
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject {
    if (!observer || !aSelector) {
        return;
    }
    YBObserverInfoModel *observerInfo = [YBObserverInfoModel new];
    observerInfo.observer = observer;
    observerInfo.selector = aSelector;
    observerInfo.object = anObject;
    observerInfo.name = aName;
    
    NSMutableDictionary *observersDic = YBNotificationCenter.defaultCenter.observersDic;
    @synchronized(observersDic) {
        NSString *key = (aName && [aName isKindOfClass:NSString.class]) ? aName : key_observersDic_noContent;
        if ([observersDic objectForKey:key]) {
            NSMutableArray *tempArr = [observersDic objectForKey:key];
            [tempArr addObject:observerInfo];
        } else {
            NSMutableArray *tempArr = [NSMutableArray array];
            [tempArr addObject:observerInfo];
            [observersDic setObject:tempArr forKey:key];
        }
    }
}

#pragma mark 发送通知
- (void)postNotification:(YBNotification *)notification {
    if (!notification) {
        return;
    }
    NSMutableDictionary *observersDic = YBNotificationCenter.defaultCenter.observersDic;
    NSMutableArray *tempArr = [observersDic objectForKey:notification.name];
    if (tempArr) {
        [tempArr enumerateObjectsUsingBlock:^(YBObserverInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.object || obj.object == notification.object) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [obj.observer performSelector:obj.selector withObject:notification];
#pragma clang diagnostic pop
            }
        }];
    }
}

#pragma mark 移除通知
- (void)removeObserver:(id)observer name:(NSString *)aName object:(id)anObject {
    if (!observer) {
        return;
    }
    if (aName && [aName isKindOfClass:[NSString class]]) {
        NSMutableDictionary *observersDic = YBNotificationCenter.defaultCenter.observersDic;
        @synchronized(observersDic) {
            NSMutableArray *tempArr = [observersDic objectForKey:[aName mutableCopy]];
            [tempArr enumerateObjectsUsingBlock:^(YBObserverInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL needRemove = obj.observer == observer && (!anObject || anObject == obj.object);
                if (needRemove) {
                    [tempArr removeObject:obj];
                }
            }];
        }
    } else {
        
    }
}

#pragma mark 单例相关方法
static YBNotificationCenter *_defaultCenter = nil;
+ (void)setDefaultCenter:(YBNotificationCenter *)x {
    _defaultCenter = x;
}
+ (YBNotificationCenter *)defaultCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultCenter = [YBNotificationCenter new];
        _defaultCenter.observersDic = [NSMutableDictionary dictionary];
    });
    return _defaultCenter;
}

@end

