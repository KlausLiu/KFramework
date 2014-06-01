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

+ (int) randomIntWithFrom:(int)from
                       to:(int)to;

#pragma mark -

+ (BOOL) isInteger:(id)obj;

+ (BOOL) isLongLong:(id)obj;

+ (BOOL) isFloat:(id)obj;

+ (BOOL) isDouble:(id)obj;

@end
