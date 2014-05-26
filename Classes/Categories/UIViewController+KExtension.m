//
//  UIViewController+KExtension.m
//  Pods
//
//  Created by corptest on 14-3-19.
//
//

#import "UIViewController+KExtension.h"
#import "UIView+KExtension.h"

@implementation UIViewController (KExtension)

- (NSArray *) sortedInputs
{
    return [self.view sortedInputs];
}

- (UIView *) focusInput
{
    NSArray *allInput = [self sortedInputs];
    for (UIView *input in allInput) {
        if ([input isFirstResponder]) {
            return input;
        }
    }
    return nil;
}

@end
