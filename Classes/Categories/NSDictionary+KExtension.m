//
//  NSDictionary+KExtension.m
//  K
//
//  Created by corptest on 14-1-6.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "NSDictionary+KExtension.h"

@implementation NSDictionary (KExtension)

- (id) objectForPath:(NSString *)path
{
    if (!path) {
        return nil;
    }
    
    NSArray *array = [path componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/."]];
    id ret = self;
    for (NSString *key in array) {
        if (!ret) {
            return nil;
        }
        if ([ret isKindOfClass:[NSDictionary class]]) {
            ret = [((NSDictionary *)ret) objectForKey:key];
        } else {
            return nil;
        }
    }
    
    return ret;
}

@end
