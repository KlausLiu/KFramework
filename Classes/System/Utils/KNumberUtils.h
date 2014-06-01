//
//  KNumberUtils.h
//  Pods
//
//  Created by corptest on 14-5-19.
//
//

#import <Foundation/Foundation.h>

@interface KNumberUtils : NSObject

#pragma mark - random

+ (int) randomIntFromZeroTo:(int)to;

+ (int) randomIntWithFrom:(int)from
                       to:(int)to;

+ (NSArray *) randomIntsWithFrom:(int)from
                              to:(int)to
                           count:(int)count;

#pragma mark -

+ (BOOL) isInteger:(id)obj;

+ (BOOL) isLongLong:(id)obj;

+ (BOOL) isFloat:(id)obj;

+ (BOOL) isDouble:(id)obj;

@end
