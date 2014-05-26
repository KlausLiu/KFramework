//
//  NSArray+KExtension.h
//  KFramework
//
//  Created by corptest on 14-1-9.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (KUtil)

/**
 *  从array中取出某元素的array
 *
 *  @param array
 *  @param closureBlock
 *
 *  @return 元素array
 */
+ (NSArray *) collectWithArray:(NSArray *)array closureBlock:(id (^)(id obj))closureBlock;
- (NSArray *) collectWithClosureBlock:(id (^)(id obj))closureBlock;

/*
 过滤出来一个
 */
- (id) filteredOneUsingPredicate:(NSPredicate *)predicate;

@end
