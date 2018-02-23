//
//  YBNotification.h
//  YBNotificationDemo
//
//  Created by 杨少 on 2018/2/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YBNotification : NSObject <NSCopying, NSCoding>

@property (readonly, copy) NSString *name;
@property (nullable, readonly, weak) id object;
@property (nullable, readonly, copy) NSDictionary *userInfo;

- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

@interface YBNotificationCenter : NSObject

@property (class, readonly, strong) YBNotificationCenter *defaultCenter;

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName object:(nullable id)anObject;

- (void)postNotification:(YBNotification *)notification;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(nullable NSString *)aName object:(nullable id)anObject;
- (void)removeObserverId:(NSString *)observerId;

//该实现有个缺陷，外部对返回值必须强持有，否则返回值会释放，就无法释放掉这个通知。
- (id<NSObject>)addObserverForName:(nullable NSString *)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(YBNotification *note))block;

@end

NS_ASSUME_NONNULL_END
