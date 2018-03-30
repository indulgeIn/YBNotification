//
//  YBNotification.m
//  YBNotificationDemo
//
//  Created by 杨少 on 2018/2/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBNotification.h"
#import <objc/runtime.h>

//发送通知消息体类
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
- (id)copyWithZone:(NSZone *)zone {
    YBNotification *model = [[[self class] allocWithZone:zone] init];
    model.name = self.name;
    model.object = self.object;
    model.userInfo = self.userInfo;
    return model;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.object forKey:@"object"];
    [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.object = [aDecoder decodeObjectForKey:@"object"];
        self.userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
    }
    return self;
}

@end


//响应者信息存储模型类
@class YBNotification;
@interface YBObserverInfoModel : NSObject
@property (weak) id observer;
@property (strong) id observer_strong;
@property (strong) NSString *observerId;
@property (assign) SEL selector;
@property (weak) id object;
@property (copy) NSString *name;
@property (strong) NSOperationQueue *queue;
@property (copy) void(^block)(YBNotification *noti);
@end
@implementation YBObserverInfoModel
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}
@end


//监听响应者释放类
@interface YBObserverMonitor : NSObject
@property (strong) NSString *observerId;
@end
@implementation YBObserverMonitor
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
    [YBNotificationCenter.defaultCenter removeObserverId:self.observerId];
}
@end


//消息中心类
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
    observerInfo.observerId = [NSString stringWithFormat:@"%@", observer];
    observerInfo.selector = aSelector;
    observerInfo.object = anObject;
    observerInfo.name = aName;
    
    [self addObserverInfo:observerInfo];
}

- (id<NSObject>)addObserverForName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(YBNotification * _Nonnull))block {
    if (!block) {
        return nil;
    }
    YBObserverInfoModel *observerInfo = [YBObserverInfoModel new];
    observerInfo.object = obj;
    observerInfo.name = name;
    observerInfo.queue = queue;
    observerInfo.block = block;
    NSObject *observer = [NSObject new];
    observerInfo.observer_strong = observer;
    observerInfo.observerId = [NSString stringWithFormat:@"%@", observer];
    
    [self addObserverInfo:observerInfo];
    return observer;
}

- (void)addObserverInfo:(YBObserverInfoModel *)observerInfo {
    
    //为observer关联一个释放监听器
    id resultObserver = observerInfo.observer ?: observerInfo.observer_strong;
    if (!resultObserver) {
        return;
    }
    YBObserverMonitor *monitor = [YBObserverMonitor new];
    monitor.observerId = observerInfo.observerId;
    const char *keyOfmonitor = [[NSString stringWithFormat:@"%@", monitor] UTF8String];
    objc_setAssociatedObject(resultObserver, keyOfmonitor, monitor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //添加进observersDic
    NSMutableDictionary *observersDic = YBNotificationCenter.defaultCenter.observersDic;
    @synchronized(observersDic) {
        NSString *key = (observerInfo.name && [observerInfo.name isKindOfClass:NSString.class]) ? observerInfo.name : key_observersDic_noContent;
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
            if (obj.block) {
                if (obj.queue) {
                    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                        obj.block(notification);
                    }];
                    NSOperationQueue *queue = obj.queue;
                    [queue addOperation:operation];
                } else {
                    obj.block(notification);
                }
            } else {
                if (!obj.object || obj.object == notification.object) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    obj.observer?[obj.observer performSelector:obj.selector withObject:notification]:nil;
#pragma clang diagnostic pop
                }
            }
        }];
    }
}
- (void)postNotificationName:(NSString *)aName object:(id)anObject {
    YBNotification *noti = [[YBNotification alloc] initWithName:aName object:anObject userInfo:nil];
    [self postNotification:noti];
}
- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    YBNotification *noti = [[YBNotification alloc] initWithName:aName object:anObject userInfo:aUserInfo];
    [self postNotification:noti];
}

#pragma mark 移除通知
//通过observer移除
- (void)removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}
- (void)removeObserver:(id)observer name:(NSString *)aName object:(id)anObject {
    if (!observer) {
        return;
    }
    [self removeObserverId:[NSString stringWithFormat:@"%@", observer] name:aName object:anObject];
}
//通过observerId移除
- (void)removeObserverId:(NSString *)observerId {
    [self removeObserverId:observerId name:nil object:nil];
}
- (void)removeObserverId:(NSString *)observerId name:(NSString *)aName object:(id)anObject {
    if (!observerId) {
        return;
    }
    NSMutableDictionary *observersDic = YBNotificationCenter.defaultCenter.observersDic;
    @synchronized(observersDic) {
        if (aName && [aName isKindOfClass:[NSString class]]) {
            NSMutableArray *tempArr = [observersDic objectForKey:[aName mutableCopy]];
            [self array_removeObserverId:observerId object:anObject array:tempArr];
        } else {
            [observersDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray *obj, BOOL * _Nonnull stop) {
                [self array_removeObserverId:observerId object:anObject array:obj];
            }];
        }
    }
}
- (void)array_removeObserverId:(NSString *)observerId object:(id)anObject array:(NSMutableArray *)array {
    @autoreleasepool {
        [array.copy enumerateObjectsUsingBlock:^(YBObserverInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.observerId isEqualToString:observerId] && (!anObject || anObject == obj.object)) {
                [array removeObject:obj];
                return;
            }
        }];
    }
}

#pragma mark 单例相关方法
static YBNotificationCenter *_defaultCenter = nil;
+ (void)setDefaultCenter:(YBNotificationCenter *)x {
    if (!self.defaultCenter) {
        _defaultCenter = x;
    }
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

