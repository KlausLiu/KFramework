//
//  UIView+KExtension.h
//  KFramework
//
//  Created by corptest on 14-1-9.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (KFrame)

- (CGFloat) x;

- (void) setX:(CGFloat)x;

- (CGFloat) y;

- (void) setY:(CGFloat)y;

- (CGPoint) origin;

- (void) setOrigin:(CGPoint)origin;

- (CGFloat) width;

- (void) setWidth:(CGFloat)width;

- (CGFloat) height;

- (void) setHeight:(CGFloat)height;

- (CGSize) size;

- (void) setSize:(CGSize)size;

@end

@interface UIView (KSuperOrSubView)

- (void) clearSubView;

- (NSArray *) allSubviews;

/**
 *  得到所有的可输入的view
 *
 *  @return 从上到下，从左到右的可输入的view的集合
 */
- (NSArray *) sortedInputs;

- (UIView *) superviewWithClass:(Class)clazz;

@end
