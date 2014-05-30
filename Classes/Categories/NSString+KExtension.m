//
//  NSString+KExtension.m
//  K
//
//  Created by corptest on 14-1-3.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "NSString+KExtension.h"
#import <CommonCrypto/CommonDigest.h>
#import "KDefine.h"
#import "KNumberUtils.h"

@implementation NSString (KExtension)

+ (BOOL) isBlank:(NSString *)str
{
    return str == nil || str.length == 0;
}

+ (BOOL) isNotBlank:(NSString *)str
{
    return ![NSString isBlank:str];
}

- (NSDictionary *) queryStringToarameterDictionary
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    if ([NSString isBlank:self]) {
        return ret;
    }
    NSArray *keyValues = [self componentsSeparatedByString:@"&"];
    for (NSString *keyValue in keyValues) {
        NSArray *kv = [keyValue componentsSeparatedByString:@"="];
        if (kv && kv.count == 2) {
            [ret setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
        }
    }
    return ret;
}

- (BOOL) isEmail
{
	NSString *		regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	return [pred evaluateWithObject:self];
}

- (BOOL) isUrl
{
    NSString *		regex = @"http(s)?:\\/\\/([\\w-]+\\.)+[\\w-]+(\\/[\\w- .\\/?%&=]*)?";
	NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	return [pred evaluateWithObject:self];
}

- (BOOL) isIPAddress
{
	NSArray *			components = [self componentsSeparatedByString:@"."];
	NSCharacterSet *	invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
	
	if ( [components count] == 4 ) {
		NSString *part1 = [components objectAtIndex:0];
		NSString *part2 = [components objectAtIndex:1];
		NSString *part3 = [components objectAtIndex:2];
		NSString *part4 = [components objectAtIndex:3];
		
		if ( [part1 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part2 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part3 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part4 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound ) {
			if ( [part1 intValue] < 255 &&
                [part2 intValue] < 255 &&
                [part3 intValue] < 255 &&
                [part4 intValue] < 255 ) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (BOOL) isEqualToStringIgnoreCase:(NSString *)aString
{
    return [[self lowercaseString] isEqualToString:[aString lowercaseString]];
}

/**
 *  去除json中的空格，回车，注释
 *
 *  @return 格式化后的json字符串
 */
- (NSString *) formatToJsonString
{
    UIWebView *_wv = [[UIWebView alloc] init];
    NSString *_ret = [_wv stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function(){var _json=%@;return JSON.stringify(_json);})();", self]];
    K_Release(_wv);
    return _ret;
}

- (BOOL) isInteger
{
    return [KNumberUtils isInteger:self];
}

- (BOOL) isLongLong
{
    return [KNumberUtils isLongLong:self];
}

- (BOOL) isFloat
{
    return [KNumberUtils isFloat:self];
}

- (BOOL) isDouble
{
    return [KNumberUtils isDouble:self];
}

@end
