//
//  UIImage+KExtension.h
//  KFramework
//
//  Created by corptest on 14-1-9.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (KCreation)

+ (UIImage *) imageWithColor:(UIColor *)color size:(CGSize)size;

@end

@interface UIImage (KExtension)

- (UIImage *) stretch;

@end
