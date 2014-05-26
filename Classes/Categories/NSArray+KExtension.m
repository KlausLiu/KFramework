//
//  NSArray+KExtension.m
//  KFramework
//
//  Created by corptest on 14-1-9.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "NSArray+KExtension.h"

@implementation NSArray (KUtil)

+ (NSArray *) collectWithArray:(NSArray *)array  closureBlock:(id (^)(id obj))closureBlock
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:array.count];
    for (id obj in array) {
        [ret addObject:closureBlock(obj)];
    }
    return ret;
}

- (NSArray *) collectWithClosureBlock:(id (^)(id obj))closureBlock
{
    return [[self class] collectWithArray:self closureBlock:closureBlock];
}

- (id) filteredOneUsingPredicate:(NSPredicate *)predicate
{
    NSArray *array = [self filteredArrayUsingPredicate:predicate];
    if (array.count > 0) {
        return [array objectAtIndex:0];
    }
    return nil;
}

@end
