//
//  NSObject+KExtension.h
//  K
//
//  Created by corptest on 14-1-3.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (KExtension)

// 执行多参数的方法
- (id) performSelector:(SEL)aSelector withArguments:(id)arg, ... NS_REQUIRES_NIL_TERMINATION;

- (void) performBlock:(void (^)(void))block delay:(NSTimeInterval)delay;

- (BOOL) is:(id)obj;

@end

#undef	CONVERT_PROPERTY_CLASS
#define	CONVERT_PROPERTY_CLASS( __name, __class ) \
    + (Class)convertPropertyClassFor_##__name \
    { \
        return NSClassFromString( [NSString stringWithUTF8String:#__class] ); \
    }

@interface NSObject (KJSON)

+ (NSArray *) objectsFromArray:(NSArray *)array;

+ (id) objectFromDictionary:(id)dic;

@end

@interface NSObject (UserDefault)

- (void) saveToUserDefaultForKey:(NSString *)key;

+ (void) userDefaultWriteObject:(id)obj forKey:(NSString *)key;

+ (id) userDefaultRead:(NSString *)key;

+ (void) userDefaultRemove:(NSString *)key;

@end


@interface NSObject (KTypeConversion)

- (NSInteger) asNSInteger;

- (long) asLong;

- (long) asLongLong;

- (float) asFloat;

- (double) asDouble;

- (BOOL) asBool;

- (NSNumber *) asNSNumber;

- (NSString *) asNSString;

- (NSDate *) asNSDate;

- (NSData *) asNSData;

- (NSArray *) asNSArray;

- (NSMutableArray *) asNSMutableArray;

- (NSString *) JSONString;

- (NSDictionary *) asNSDictionary;

- (NSMutableDictionary *) asNSMutableDictionary;

@end
