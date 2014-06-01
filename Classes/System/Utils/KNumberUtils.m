//
//  KNumberUtils.m
//  Pods
//
//  Created by corptest on 14-5-19.
//
//

#import "KNumberUtils.h"

@implementation KNumberUtils

+ (int) randomIntFromZeroTo:(int)to
{
    return [self randomIntWithFrom:0
                                to:to];
}

+ (int) randomIntWithFrom:(int)from
                       to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}

+ (NSArray *) randomIntsWithFrom:(int)from
                              to:(int)to
                           count:(int)count
{
    NSMutableArray *tmp = [NSMutableArray array];
    for (; from <= to; from ++) {
        [tmp addObject:@(from)];
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    count = (count < tmp.count ? count : tmp.count);
    for (int i = 0; i < count; i ++) {
        id obj = tmp[[self randomIntFromZeroTo:(tmp.count - 1)]];
        [result addObject:obj];
        [tmp removeObject:obj];
    }
    return result;
}

+ (BOOL) isInteger:(id)obj
{
    NSScanner *scanner = [NSScanner scannerWithString:[obj description]];
    int i;
    return [scanner scanInt:&i] && [scanner isAtEnd];
}

+ (BOOL) isLongLong:(id)obj
{
    NSScanner *scanner = [NSScanner scannerWithString:[obj description]];
    long long ll;
    return [scanner scanLongLong:&ll] && [scanner isAtEnd];
}

+ (BOOL) isFloat:(id)obj
{
    NSScanner *scanner = [NSScanner scannerWithString:[obj description]];
    float f;
    return [scanner scanFloat:&f] && [scanner isAtEnd];
}

+ (BOOL) isDouble:(id)obj
{
    NSScanner *scanner = [NSScanner scannerWithString:[obj description]];
    double d;
    return [scanner scanDouble:&d] && [scanner isAtEnd];
}

@end
