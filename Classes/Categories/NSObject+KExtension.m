//
//  NSObject+KExtension.m
//  K
//
//  Created by corptest on 14-1-3.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "NSObject+KExtension.h"
#import "NSDictionary+KExtension.h"
#import "KDefine.h"
#import <objc/runtime.h>
#import "JSONKit.h"
#import "KClassUtils.h"

@implementation NSObject (KExtension)

- (id) performSelector:(SEL)aSelector withArguments:(id)arg, ...
{
    NSMethodSignature *sig = [self methodSignatureForSelector:aSelector];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setTarget:self];
    [inv setSelector:aSelector];
    // 0被target占用，1被selector占用，故参数从2开始
    int index = 2;
    if (arg) {
        [inv setArgument:&arg atIndex:index];
        id argVa;
        va_list args;
        va_start(args, arg);
        while ((argVa = va_arg(args, id))) {
            index ++;
            [inv setArgument:&argVa atIndex:index];
        }
        va_end(args);
        [inv retainArguments];
    }
    [inv invoke];
    id ret = nil;
    [inv getReturnValue:&ret];
    return ret;
}

- (void) performBlock:(void (^)(void))block delay:(NSTimeInterval)delay
{
    block = [block copy];
    [self performSelector:@selector(_doPerformBlock:)
               withObject:block
               afterDelay:delay];
}

- (void) _doPerformBlock:(void (^)(void))block
{
    block();
    K_Release(block);
}

- (BOOL) is:(id)obj
{
    return self == obj;
}

@end

@implementation NSObject (KJSON)

+ (NSArray *) objectsFromArray:(NSArray *)array
{
    if (nil == array) {
		return nil;
	}
    
	if (NO == [array isKindOfClass:[NSArray class]]) {
		return nil;
	}
    NSMutableArray * results = [NSMutableArray array];
    __strong NSObject *obj;
	for (obj in (NSArray *)array) {
		if ([obj isKindOfClass:[NSDictionary class]]) {
			obj = [self objectFromDictionary:obj];
			if (obj) {
				[results addObject:obj];
			}
		} else {
			[results addObject:obj];
		}
	}
    
	return results;
}

+ (id) objectFromDictionary:(NSDictionary *)dic
{
    if (nil == dic) {
		return nil;
	}
	if (NO == [dic isKindOfClass:[NSDictionary class]]) {
		return nil;
	}
    Class clazz = [self class];
    id object = [[clazz alloc] init];
    if (nil == object) {
        return nil;
    }
    unsigned int        propertyCount = 0;
    objc_property_t *   properties = class_copyPropertyList(clazz, &propertyCount);
    
    for (int i = 0; i < propertyCount; i ++) {
        const char *    name = property_getName(properties[i]);
        NSString *      propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        const char *    attr = property_getAttributes(properties[i]);
        NSObject *tmpValue = [dic objectForKey:propertyName];
        KClassType type = [KClassUtils typeWithObject:tmpValue];
        id value = nil;
        if (tmpValue) {
            if (type == KClassType_Int_NSInteger) {
                value = @([tmpValue asNSInteger]);
            } else if (type == KClassType_Long) {
                value = @([tmpValue asLong]);
            } else if (type == KClassType_Long_Long) {
                value = @([tmpValue asLongLong]);
            } else if (type == KClassType_Float_CGFloat) {
                value = @([tmpValue asFloat]);
            } else if (type == KClassType_Double) {
                value = @([tmpValue asDouble]);
            } else if (type == KClassType_NSNumber) {
                value = [tmpValue asNSNumber];
            } else if (type == KClassType_NSString) {
                value = [tmpValue asNSString];
            } else if (type == KClassType_NSDate) {
                value = [tmpValue asNSDate];
            } else if (type == KClassType_NSArray) {
                if ([tmpValue isKindOfClass:[NSArray class]]) {
                    SEL convertSelector = NSSelectorFromString( [NSString stringWithFormat:@"convertPropertyClassFor_%@", propertyName] );
                    if ( [clazz respondsToSelector:convertSelector] ) {
                        IMP m = [clazz methodForSelector:convertSelector];
                        Class convertClass = m(clazz, convertSelector);
                        if (convertClass) {
                            NSMutableArray * arrayTemp = [NSMutableArray array];
                            
                            for (NSObject * tempObject in (NSArray *)tmpValue) {
                                if ([tempObject isKindOfClass:[NSDictionary class]]) {
                                    [arrayTemp addObject:[convertClass objectFromDictionary:(NSDictionary *)tempObject]];
                                }
                            }
                            value = arrayTemp;
                        } else {
                            value = tmpValue;
                        }
                    } else {
                        value = tmpValue;
                    }
                }
            } else if (type == KClassType_NSDictionary) {
                if ( [tmpValue isKindOfClass:[NSDictionary class]] ) {
                    SEL convertSelector = NSSelectorFromString( [NSString stringWithFormat:@"convertPropertyClassFor_%@", propertyName] );
                    if ( [clazz respondsToSelector:convertSelector] ) {
                        IMP m = [clazz methodForSelector:convertSelector];
                        Class convertClass = m(clazz, convertSelector);
                        if ( convertClass ) {
                            value = [convertClass objectFromDictionary:(NSDictionary *)tmpValue];
                        } else {
                            value = tmpValue;
                        }
                    } else {
                        value = tmpValue;
                    }
                }
            } else if (type == KClassType_Object) {
                Class cz = [KClassUtils classWithPropertyName:propertyName
                                                      inClass:clazz];
                if ([tmpValue isKindOfClass:cz]) {
                    value = tmpValue;
                } else if ([tmpValue isKindOfClass:[NSDictionary class]]) {
                    value = [cz objectFromDictionary:((NSDictionary *)tmpValue)];
                }
            }
        }
        if (value) {
            [object setValue:value forKey:propertyName];
        }
    }
    
    if (properties) {
        free(properties);
    }
    
    return K_Auto_Release(object);
}

@end

@implementation NSObject (UserDefault)

- (void) saveToUserDefaultForKey:(NSString *)key
{
    [[self class] userDefaultWriteObject:self forKey:key];
}

+ (void) userDefaultWriteObject:(id)obj forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id) userDefaultRead:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

+ (void) userDefaultRemove:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end


@implementation NSObject (KTypeConversion)

- (NSInteger) asNSInteger
{
    return ((NSString *)self).integerValue;
}

- (long) asLong
{
    return (long)((NSString *)self).longLongValue;
}

- (long) asLongLong
{
    return ((NSString *)self).longLongValue;
}

- (float) asFloat
{
    return ((NSString *)self).floatValue;
}

- (double) asDouble
{
    return ((NSString *)self).doubleValue;
}

- (BOOL) asBool
{
	return [[self asNSNumber] boolValue];
}

- (NSNumber *) asNSNumber
{
	if ([self isKindOfClass:[NSNumber class]]) {
		return (NSNumber *)self;
	} else if ([self isKindOfClass:[NSString class]]) {
		return [NSNumber numberWithInteger:[(NSString *)self integerValue]];
	} else if ([self isKindOfClass:[NSDate class]]) {
		return [NSNumber numberWithDouble:[(NSDate *)self timeIntervalSince1970]];
	} else if ([self isKindOfClass:[NSNull class]]) {
		return [NSNumber numberWithInteger:0];
	}
    
	return nil;
}

- (NSString *) asNSString
{
	if ( [self isKindOfClass:[NSNull class]] )
		return nil;
    
	if ( [self isKindOfClass:[NSString class]] )
	{
		return (NSString *)self;
	}
	else if ( [self isKindOfClass:[NSData class]] )
	{
		NSData * data = (NSData *)self;
		return K_Auto_Release([[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding]);
	}
	else
	{
		return [NSString stringWithFormat:@"%@", self];
	}
}

- (NSDate *) asNSDate
{
	if ( [self isKindOfClass:[NSDate class]] )
	{
		return (NSDate *)self;
	}
	else if ( [self isKindOfClass:[NSString class]] )
	{
		NSDate * date = nil;
        
		if ( nil == date )
		{
			NSString * format = @"yyyy-MM-dd HH:mm:ss z";
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:format];
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            
			date = [formatter dateFromString:(NSString *)self];
            K_Release(formatter);
		}
        
		if ( nil == date )
		{
			NSString * format = @"yyyy/MM/dd HH:mm:ss z";
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:format];
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			
			date = [formatter dateFromString:(NSString *)self];
            K_Release(formatter);
		}
        
		if ( nil == date )
		{
			NSString * format = @"yyyy-MM-dd HH:mm:ss";
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:format];
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			
			date = [formatter dateFromString:(NSString *)self];
            K_Release(formatter);
		}
        
		if ( nil == date )
		{
			NSString * format = @"yyyy/MM/dd HH:mm:ss";
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:format];
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			
			date = [formatter dateFromString:(NSString *)self];
            K_Release(formatter);
		}
        
		return date;
	}
	else
	{
		return [NSDate dateWithTimeIntervalSince1970:[self asNSNumber].doubleValue];
	}
	
	return nil;
}

- (NSData *) asNSData
{
	if ( [self isKindOfClass:[NSString class]]) {
		return [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	}
	else if ( [self isKindOfClass:[NSData class]] )
	{
		return (NSData *)self;
	}
    
	return nil;
}

- (NSArray *) asNSArray
{
	if ( [self isKindOfClass:[NSArray class]] )
	{
		return (NSArray *)self;
	}
	else
	{
		return [NSArray arrayWithObject:self];
	}
}

- (NSMutableArray *) asNSMutableArray
{
	if ( [self isKindOfClass:[NSMutableArray class]] )
	{
		return (NSMutableArray *)self;
	}
	
	return nil;
}

- (NSString *) JSONString
{
    id dic = [self asNSDictionary];
    if ([dic isKindOfClass:[NSDictionary class]] ||[dic isKindOfClass:[NSArray class]]) {
        return [dic JSONString];
    }
    return nil;
}

- (id) asNSDictionary
{
	if ([self isKindOfClass:[NSNumber class]]) {
        return self;
    }
    if ([self isKindOfClass:[NSString class]]) {
        return self;
    }
    if ([self isKindOfClass:[NSDate class]]) {
        return self;
    }
    if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *a1 = [NSMutableArray arrayWithCapacity:((NSArray *)self).count];
        for (id obj in (NSArray *)self) {
            [a1 addObject:[obj asNSDictionary]];
        }
        return a1;
    }
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d1 = [NSMutableDictionary dictionaryWithCapacity:((NSDictionary *)self).count];
        for (id key in [((NSDictionary *)self) allKeys]) {
            [d1 setObject:[[((NSDictionary *)self) objectForKey:key] asNSDictionary]
                   forKey:key];
        }
        return d1;
    }
    unsigned int propertyCount = 0;
    objc_property_t * properties = class_copyPropertyList([self class], &propertyCount);
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:propertyCount];
    for (int i = 0; i < propertyCount; i ++) {
        const char * name = property_getName(properties[i]);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        id value = [self valueForKey:propertyName];
        NSInteger type = [KClassUtils typeWithObject:value];
        id result = nil;
        if (type == KClassType_NSArray) {
            if ([value isKindOfClass:[NSArray class]]) {
                NSMutableArray *a1 = [NSMutableArray arrayWithCapacity:((NSArray *)value).count];
                for (id obj in (NSArray *)value) {
                    [a1 addObject:[obj asNSDictionary]];
                }
                result = a1;
            } else {
                result = value;
            }
        } else if (type == KClassType_NSDictionary) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *d1 = [NSMutableDictionary dictionaryWithCapacity:((NSDictionary *)value).count];
                for (id key in [((NSDictionary *)value) allKeys]) {
                    [d1 setObject:[[((NSDictionary *)value) objectForKey:key] asNSDictionary]
                           forKey:key];
                }
                result = d1;
            } else {
                result = value;
            }
        } else if (type == KClassType_Unknow) {
            if ([value isKindOfClass:[NSObject class]]) {
                result = [value asNSDictionary];
            } else {
                result = value;
            }
        } else if (type == KClassType_Object) {
            result = [value asNSDictionary];
        } else {
            result = value;
        }
        if (value) {
            [dic setObject:result forKey:propertyName];
        }
    }
    return dic;
}

- (NSMutableDictionary *) asNSMutableDictionary
{
	if ( [self isKindOfClass:[NSMutableDictionary class]] )
	{
		return (NSMutableDictionary *)self;
	}
	
	NSDictionary * dict = [self asNSDictionary];
	if ( nil == dict )
		return nil;
    
	return [NSMutableDictionary dictionaryWithDictionary:dict];
}

@end
