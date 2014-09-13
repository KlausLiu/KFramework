//
//  KBaseModel.h
//  KFramework
//
//  Created by corptest on 14-1-7.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMessage.h"
#import "JSONKit.h"
#import "KCategories.h"

#if __has_feature(objc_instancetype)

#undef AS_SINGLETEN
#define AS_SINGLETEN(...) \
- (instancetype) sharedInstance; \
+ (instancetype) sharedInstance;

#undef DEF_SINGLETEN
#define DEF_SINGLETEN(...) \
- (instancetype) sharedInstance \
{ \
return [[self class] sharedInstance];\
} \
+ (instancetype) sharedInstance \
{ \
static dispatch_once_t once; \
static id __singleton__; \
dispatch_once( &once, ^{ __singleton__ = [[self alloc] init]; } ); \
return __singleton__; \
}

#else

#undef AS_SINGLETEN
#define AS_SINGLETEN(__class) \
- (__class *) sharedInstance; \
+ (__class *) sharedInstance;

#undef	DEF_SINGLETON
#define DEF_SINGLETON( __class ) \
- (__class *)sharedInstance \
{ \
return [__class sharedInstance]; \
} \
+ (__class *)sharedInstance \
{ \
static dispatch_once_t once; \
static __class * __singleton__; \
dispatch_once( &once, ^{ __singleton__ = [[[self class] alloc] init]; } ); \
return __singleton__; \
}

#endif

@protocol KModelObserver <NSObject>

@optional
- (void) handleMessage:(KMessage *)message;

/**
 *  预处理
 *
 *  @param message
 *
 *  @return YES：成功，继续处理；NO：失败
 */
- (BOOL) preHandleMessage:(KMessage *)message;

@end

@interface KModel : NSObject <KModelObserver>

- (instancetype) addObserver:(id<KModelObserver>)observer;

- (instancetype) removeObserver:(id<KModelObserver>)observer;

#pragma mark - message

- (KMessage *) message:(NSString *)url;

@end
