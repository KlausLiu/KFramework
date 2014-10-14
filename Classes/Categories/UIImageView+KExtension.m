//
//  UIImageView+KExtension.m
//  Pods
//
//  Created by Klaus on 14-10-11.
//
//

#import "UIImageView+KExtension.h"
#import <CoreGraphics/CoreGraphics.h>
#import "UIView+KExtension.h"

@implementation UIImageView (KExtension)

/**
 *  改为圆形图
 */
- (void) toWhole
{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = MIN(self.width, self.height) / 2;
}

@end
